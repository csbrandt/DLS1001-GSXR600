//////////////////////////////
// Filename: DLS1001_GSXR600
// Created By: Christopher Brandt
// Created Date: 03-08-2010
//////////////////////////////

#include "sd-reader_config.h"
#include "sd_raw.h"
#include "sd_raw_config.h"
#include "prescaler.h"

//////////////////////////////

#define SLAVESELECT_ACC 9 // SS1
#define SLAVESELECT_SD 10 // SS2
#define DATAOUT        11 // MOSI
#define DATAIN         12 // MISO 
#define SPICLOCK       13 // SCK

#define TRIGGER         3

#define DEVID          0x00
#define BW_RATE        0x2C
#define DATA_FORMAT    0x31
#define POWER_CTL      0x2D
#define DATAX0         0x32
#define DATAY0         0x34
#define DATAZ0         0x36
#define FIFO_CTL       0x38

//////////////////////////////

void spi_init_acc();
int  print_disk_info();
byte read_register(byte register_name, int slave_select);
void write_register(byte register_name, byte register_value, int slave_select);

//////////////////////////////


void setup()
{
  byte bTemp;
  
  Serial.begin(9600);
  
  // Change clock prescale
  
  setClockPrescaler(CLOCK_PRESCALER_4);
  
  Serial.print("Clock division factor: ");
  Serial.print(getClockDivisionFactor());
  
  //////////////////////////////
  
  trueDelay(100);
  
  pinMode(SLAVESELECT_ACC, OUTPUT);
  pinMode(SLAVESELECT_SD, OUTPUT);
  pinMode(DATAOUT, OUTPUT);
  pinMode(DATAIN, INPUT);
  pinMode(SPICLOCK, OUTPUT);
  
  pinMode(TRIGGER, OUTPUT);
  
  // Disable all devices
  
  digitalWrite(SLAVESELECT_ACC, HIGH); // Disable Accelerometer
  digitalWrite(SLAVESELECT_SD, HIGH);  // Disable SD Card
  
  digitalWrite(TRIGGER, LOW);
  
  //////////////////////////////
  /*
  if(!sd_raw_init())
  {
     Serial.println("MMC/SD initialization failed");
  }
  else
  {
    print_disk_info();
  }
  */
  spi_init_acc();
  
  Serial.println();
  Serial.println();
  Serial.print("SPI control register: ");
  Serial.print(SPCR, BIN);
  
  bTemp = read_register(DEVID, SLAVESELECT_ACC);
  
  
  Serial.println();
  Serial.print("Accelerometer Device ID: ");
  Serial.print(bTemp, BIN);
  
  bTemp = read_register(BW_RATE, SLAVESELECT_ACC);
  
  Serial.println();
  Serial.print("BW_RATE Value: ");
  Serial.print(bTemp, BIN);
  
  bTemp = read_register(DATA_FORMAT, SLAVESELECT_ACC);
  
  Serial.println();
  Serial.print("DATA_FORMAT Value: ");
  Serial.print(bTemp, BIN);
  
  bTemp = read_register(DATAX0, SLAVESELECT_ACC);
  
  Serial.println();
  Serial.print("DATAX0 Value: ");
  Serial.print(bTemp, BIN);
}

void loop()
{
 
}

// Initializes SPI communication specifically for the accelerometer
// This will be called each time before communicating with the accelerometer
// because other devices are on the same SPI bus and we are not assuming the same
// settings for each device.
void spi_init_acc()
{
  byte bCLR; // Byte used to clear data from registers
  byte in_byte = 0x00;
  
  digitalWrite(SLAVESELECT_SD, HIGH);  // Disable SD Card
  
  //////////////////////////////
  // Initialize SPI control register (SPCR)
  // SPIE = 0
  // SPE  = 1 (On)
  // DORD = 0 (MSB first)
  // MSTR = 1 (Master)
  // CPOL = 1 (SCK High when idle)
  // CPHA = 1 (Sample data on trailing edge of clock)
  // SPR1/SPR0 = 11 (slowest (250KHz)
  
  SPCR = B01011111;
  
  //////////////////////////////
  // Clear SPI status and data registers
  
  bCLR = SPSR;
  bCLR = SPDR;
  
  trueDelay(4000);
  
  //////////////////////////////
  // Setup proper values for POWER_CTL
  // Not used   = 0
  // Not used   = 0
  // Link       = 0
  // AUTO_SLEEP = 0 
  // Measure    = 1
  // Sleep      = 0 (Normal mode)
  // Wakeup     = 00
  
  write_register(POWER_CTL, B00000000, SLAVESELECT_ACC);
  
  while (in_byte != 0x8)
  {
     write_register(POWER_CTL, B00001000, SLAVESELECT_ACC);
  
     in_byte = read_register(POWER_CTL, SLAVESELECT_ACC);
  
     Serial.println();
     Serial.print("POWER_CTL Value: ");
     Serial.print(in_byte, BIN);
  
     trueDelay(1000);
  }
    
  
  //////////////////////////////
  // Setup proper values for DATA_FORMAT
  // SELF_TEST  = 0
  // SPI        = 0  (0: 4-Wire SPI / 1: 3-Wire SPI)
  // INT_INVERT = 0
  // Not used   = 0
  // FULL_RES   = 0
  // Justify    = 0
  // Range      = 10 (Range: 8g)
  
  while (in_byte != 0x2)
  {
    write_register(DATA_FORMAT, B00000010, SLAVESELECT_ACC);
    
    in_byte = read_register(DATA_FORMAT, SLAVESELECT_ACC);
    
    Serial.println();
     Serial.print("DATA_FORMAT Value: ");
     Serial.print(in_byte, BIN);
  
     trueDelay(1000);
  }
  
  //////////////////////////////
  // Setup proper values for BW_RATE
  // Not used   = 0
  // Not used   = 0
  // Not used   = 0
  // LOW_POWER  = 0    (Normal operation)
  // Rate       = 1010 (100 Hz)
  
  write_register(BW_RATE, B00001010, SLAVESELECT_ACC);
  
  //////////////////////////////
  // Setup proper values for FIFO_CTL
  // FIFO_MODE  = 00 (Bypass)
  // Trigger    = 0
  // Samples    = 00000
  
  write_register(FIFO_CTL, 0, SLAVESELECT_ACC);
}

int print_disk_info()
{
    struct sd_raw_info disk_info;
    if(!sd_raw_get_info(&disk_info))
    {
	  return 0;
    }

    Serial.println();
    Serial.print("rev:    ");
    Serial.print(disk_info.revision,HEX);
    Serial.println();
    Serial.print("serial: 0x");
    Serial.print(disk_info.serial,HEX);
    Serial.println();
    Serial.print("date:   ");
    Serial.print(disk_info.manufacturing_month,DEC);
    Serial.println();
    Serial.print(disk_info.manufacturing_year,DEC);
    Serial.println();
    Serial.print("size:   ");
    Serial.print((disk_info.capacity / 1048576), DEC);
    Serial.print(" MB");
    Serial.println();
    Serial.print("copy:   ");
    Serial.print(disk_info.flag_copy,DEC);
    Serial.println();
    Serial.print("wr.pr.: ");
    Serial.print(disk_info.flag_write_protect_temp,DEC);
    Serial.print('/');
    Serial.print(disk_info.flag_write_protect,DEC);
    Serial.println();
    Serial.print("format: ");
    Serial.print(disk_info.format,DEC);
    Serial.println();
    Serial.print("free:   ");
    Serial.println();
    Serial.println();

    return 1;
}

byte read_register(byte register_name, int slave_select)
{
   byte in_byte;
   
   register_name |= 0x80; // Set read bit
   
   // Trigger
   
   if (register_name == (POWER_CTL | 0x80))
   {
      digitalWrite(TRIGGER, HIGH);
   }
      
   //////////////////////////////
   
   // SS is active low
   digitalWrite(slave_select, LOW);
   
   spi_transfer(register_name);
   spi_transfer(0x00);
   
   in_byte = SPDR;
   
   // deselect the device
   digitalWrite(slave_select, HIGH);
   
   return in_byte;
}

void write_register(byte register_name, byte register_value, int slave_select)
{
   digitalWrite(TRIGGER, HIGH);
   // SS is active low
   digitalWrite(slave_select, LOW);
   spi_transfer(register_name); //Send register location
   spi_transfer(register_value); //Send value to record into register
   
   digitalWrite(slave_select, HIGH);
   
   trueDelay(5);
}

void spi_transfer(volatile byte data)
{
  SPDR = data;                    // Start the transmission
  
  while (!(SPSR & (1<<SPIF)))     // Wait for the end of the transmission
  {
  };
}

  





  
  
  
  
  
  
  
  
  
