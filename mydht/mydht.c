#include <linux/module.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <asm/uaccess.h>
#include <linux/pci.h>
#include <linux/version.h>
#include <asm/gpio.h>
#include <linux/delay.h>

#include "mydht.h"

#define DHT1_PIN 4
#define DHT2_PIN 3
#define DHT_PULSES 41
#define DHT_MAXCOUNT 100
//создаем буфер для сообщения с фиксированной максимальной длинной.
#define LEN_MSG 160
static char buf_msg1[ LEN_MSG + 1 ] = "Hello from module!\n";
static char buf_msg2[ LEN_MSG + 1 ] = "Hello from module!\n";


// функция чтения данных с DHT22 N1

int readDHT1() {
 int counter = 0;
 int i=0;
 int v;
 int threshold;
 unsigned long flags = 0;
 int bits[100], data[10];

 data[0] = data[1] = data[2] = data[3] = data[4] = 0;

 // clear bits
 for (i=0; i < DHT_PULSES*2; i++) {
  bits[i] = 0;
 }

 local_irq_save(flags);

 gpio_direction_output(DHT1_PIN, 1);
 gpio_set_value(DHT1_PIN,1);
 udelay(100);
 gpio_set_value(DHT1_PIN,0);
 //msleep(5);
 udelay(1000);
 gpio_set_value(DHT1_PIN,1);
 gpio_direction_input(DHT1_PIN);
 udelay(2);

 
 
 // Wait for DHT to pull pin low.
 counter = 0;
 while (gpio_get_value(DHT1_PIN)) {
	if (++counter >= DHT_MAXCOUNT) {
	// Timeout waiting for response.
	strcpy(buf_msg1,"Timeout 1\n");
	return 1;
	}
	udelay(1);
 }

 

 // Record pulse widths for the expected result bits.
 for (i=0; i < DHT_PULSES*2; i+=2) {
  // Count how long pin is low and store in pulseCounts[i]
  while (gpio_get_value(DHT1_PIN) == 0) {
	if (++bits[i] >= DHT_MAXCOUNT) {
	sprintf(buf_msg1,"Timeout 2 %d", i);
	local_irq_restore(flags);
	return 1;
	}
	udelay(1);
  }
  // Count how long pin is high and store in pulseCounts[i+1]
  while (gpio_get_value(DHT1_PIN)) {
	if (++bits[i+1] >= DHT_MAXCOUNT) {
	sprintf(buf_msg1,"Timeout 3 %d\n", i);
	local_irq_restore(flags);
	return 1;
	}
	udelay(1);
  }
 }
 local_irq_restore(flags);

 // Compute the average low pulse width to use as a 50 microsecond reference threshold.
 // Ignore the first two readings because they are a constant 80 microsecond pulse.
 threshold = 0;
 for (i=2; i < DHT_PULSES*2; i+=2) {
	threshold += bits[i];
 }
 threshold /= DHT_PULSES-1;

 // Interpret each high pulse as a 0 or 1 by comparing it to the 50us reference.
 // If the count is less than 50us it must be a ~28us 0 pulse, and if it's higher
 // then it must be a ~70us 1 pulse.
 for (i=3; i < DHT_PULSES*2; i+=2) {
	int index = (i-3)/16;
	data[index] <<= 1;
	if (bits[i] >= threshold) {
	// One bit for long pulse.
		data[index] |= 1;
	}
	// Else zero bit for short pulse.
 }


 v = ((data[0] + data[1] + data[2] + data[3]) & 0xFF);
 //sprintf(buf_msg, "Data (%d): 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n", threshold, data[0], data[1], data[2], data[3], data[4], v);

if (data[4] == v)
{
  int h,h1;
  int t,t1;
  h = data[0]*256 + data[1];
  t = (data[2] & 0x7F)*256 + data[3];
  h1 = h % 10;
  t1 = t % 10;
  h /= 10;
  t /= 10;
  if(data[2] & 0x80) 
  	sprintf(buf_msg1,"OK %d.%d -%d.%d\n", h, h1, t, t1);
  else
  	sprintf(buf_msg1,"OK %d.%d %d.%d\n", h, h1, t, t1);
}
else
{
  strcpy(buf_msg1, "CRC Error");
}

return 0;
}

// функция чтения данных с DHT22 N1

int readDHT2() {
 int counter = 0;
 int i=0;
 int v;
 int threshold;
 unsigned long flags = 0;
 int bits[100], data[10];

 data[0] = data[1] = data[2] = data[3] = data[4] = 0;

 // clear bits
 for (i=0; i < DHT_PULSES*2; i++) {
  bits[i] = 0;
 }

local_irq_save(flags);
 
 gpio_direction_output(DHT2_PIN, 1);
 gpio_set_value(DHT2_PIN,1);
 udelay(100);
 gpio_set_value(DHT2_PIN,0);
//msleep(5);
 udelay(1000);
 gpio_set_value(DHT2_PIN,1);
 gpio_direction_input(DHT2_PIN);
 udelay(2);

 
 // Wait for DHT to pull pin low.
 counter = 0;
 while (gpio_get_value(DHT2_PIN)) {
	if (++counter >= DHT_MAXCOUNT) {
	// Timeout waiting for response.
	strcpy(buf_msg2,"Timeout 1\n");
	return 1;
	}
	udelay(1);
 }

 
 
 // Record pulse widths for the expected result bits.
 for (i=0; i < DHT_PULSES*2; i+=2) {
  // Count how long pin is low and store in pulseCounts[i]
  while (gpio_get_value(DHT2_PIN) == 0) {
	if (++bits[i] >= DHT_MAXCOUNT) {
	sprintf(buf_msg2,"Timeout 2 %d", i);
	local_irq_restore(flags);
	return 1;
	}
	udelay(1);
  }
  // Count how long pin is high and store in pulseCounts[i+1]
  while (gpio_get_value(DHT2_PIN)) {
	if (++bits[i+1] >= DHT_MAXCOUNT) {
	sprintf(buf_msg2,"Timeout 3 %d\n", i);
	local_irq_restore(flags);
	return 1;
	}
	udelay(1);
  }
 }
 local_irq_restore(flags);

 // Compute the average low pulse width to use as a 50 microsecond reference threshold.
 // Ignore the first two readings because they are a constant 80 microsecond pulse.
 threshold = 0;
 for (i=2; i < DHT_PULSES*2; i+=2) {
	threshold += bits[i];
 }
 threshold /= DHT_PULSES-1;

 // Interpret each high pulse as a 0 or 1 by comparing it to the 50us reference.
 // If the count is less than 50us it must be a ~28us 0 pulse, and if it's higher
 // then it must be a ~70us 1 pulse.
 for (i=3; i < DHT_PULSES*2; i+=2) {
	int index = (i-3)/16;
	data[index] <<= 1;
	if (bits[i] >= threshold) {
	// One bit for long pulse.
		data[index] |= 1;
	}
	// Else zero bit for short pulse.
 }


 v = ((data[0] + data[1] + data[2] + data[3]) & 0xFF);
 //sprintf(buf_msg, "Data (%d): 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x\n", threshold, data[0], data[1], data[2], data[3], data[4], v);

if (data[4] == v)
{
  int h,h1;
  int t,t1;
  h = data[0]*256 + data[1];
  t = (data[2] & 0x7F)*256 + data[3];
  h1 = h % 10;
  t1 = t % 10;
  h /= 10;
  t /= 10;
  if(data[2] & 0x80) 
  	sprintf(buf_msg2,"OK %d.%d -%d.%d\n", h, h1, t, t1);
  else
  	sprintf(buf_msg2,"OK %d.%d %d.%d\n", h, h1, t, t1);
}
else
{
  strcpy(buf_msg2, "CRC Error");
}

return 0;
}


//функция x_show вызывается при чтении файла, через который предоставляется интерфейс. 
//для каждого файла назначается своя функция обработчик
// *buf - указатель на буфер, куда положить результат
static ssize_t x_show( struct class *class, struct class_attribute *attr, char *buf ) {
   
   readDHT1();
   strcpy(buf, buf_msg1);
   //printk( "read %d\n", strlen( buf ) );
   return strlen( buf ); // необходимо вернуть длину передаваемого сообщения
}

//аналогично функции x_show, но вызывается при записи в файл интерфейса
// * buf - указатель на буфер входного параметра, count - длинна буфера
static ssize_t x_store( struct class *class, struct class_attribute *attr, const char *buf, size_t count ) {
   //printk( "write %d\n" , count );
   //strncpy( buf_msg, buf, count );
   //buf_msg[ count ] = '\0';
   return count;
}

// *buf - указатель на буфер, куда положить результат
static ssize_t x_show1( struct class *class, struct class_attribute *attr, char *buf ) {
   
   readDHT2();
   strcpy(buf, buf_msg2);
   //printk( "read %d\n", strlen( buf ) );
   return strlen( buf ); // необходимо вернуть длину передаваемого сообщения
}

//аналогично функции x_show, но вызывается при записи в файл интерфейса
// * buf - указатель на буфер входного параметра, count - длинна буфера
static ssize_t x_store1( struct class *class, struct class_attribute *attr, const char *buf, size_t count ) {
   //printk( "write %d\n" , count );
   //strncpy( buf_msg, buf, count );
   //buf_msg[ count ] = '\0';
   return count;
}

//декларация интерфейса, здесь мы описали название файла, права доступа, 
//передали указатели на функции - обработчики
CLASS_ATTR( dht1, 0666, &x_show, &x_store);
CLASS_ATTR( dht2, 0666, &x_show1, &x_store1);

//указатель на структуру в /sys/class
static struct class *x_class;

int __init x_init(void) {
   int res;
   //создаем класс и указываем имя интерфейса, которое и будет именем каталога в /sys/class
   x_class = class_create( THIS_MODULE, "my" );
   if( IS_ERR( x_class ) ) printk( "bad class create\n" );
   //создаем файл интерфеса. x_class - структура класса, в котором расположен интерфейс
   //class_attr_xxx - создается макросом CLASS_ATTR. 
   //xxx на конце - имя объекта, переданное первым параметром в макрос.
   //x_class - имя класса, где создается интерфейс (т.к. у модуля их может быть несколько)
   res = class_create_file( x_class, &class_attr_dht1 );
   res = class_create_file( x_class, &class_attr_dht2 );
   
   res = gpio_request(DHT1_PIN, "my");
   if (res) {
      printk("'dht' error request gpio DHT1\n");
   }
   //gpio_direction_output(DHT1_PIN, 1);
   gpio_direction_input(DHT1_PIN);
   
   res = gpio_request(DHT2_PIN, "my");
   if (res) {
      printk("'dht' error request gpio DHT2\n");
   }
   //gpio_direction_output(DHT1_PIN, 1);
   gpio_direction_input(DHT2_PIN);
 
   printk("'mydht' module initialized\n");
   return 0;
}

void x_cleanup(void) {
   gpio_free(DHT1_PIN);
   gpio_free(DHT2_PIN);
   //удаляем интерфейс
   class_remove_file( x_class, &class_attr_dht1 );
   class_remove_file( x_class, &class_attr_dht2 );
   //и сам класс
   class_destroy( x_class );
   return;
}

module_init( x_init );
module_exit( x_cleanup );
MODULE_LICENSE( "GPL" );


