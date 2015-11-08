
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <modbus.h>
int main()
{
modbus_t *ctx;
uint16_t tab_reg[64];
int rc;
int i;
struct timeval response_timeout;
// create your modbus device object
/*modbus_t *modbus_new_rtu(
const char *device, int baud, char parity, int data_bit, int stop_bit);*/

ctx = modbus_new_rtu("/dev/ttyUSB0", 9600, 'N', 8, 1);
// check if object was created successfully
if (ctx == NULL) {
    fprintf(stderr, "Unable to create the libmodbus context\n");
    return -1;
}

//modbus_set_debug(ctx, TRUE);
modbus_set_error_recovery(ctx,
                              MODBUS_ERROR_RECOVERY_LINK |
                              MODBUS_ERROR_RECOVERY_PROTOCOL);

modbus_set_slave(ctx, 1);
response_timeout.tv_sec = 1;
response_timeout.tv_usec = 0;
modbus_set_response_timeout(ctx, &response_timeout);


if (modbus_connect(ctx) == -1) {
        fprintf(stderr, "Connection failed: %s\n",
        modbus_strerror(errno));
        modbus_free(ctx);
        return -1;
    }


rc = modbus_read_registers(ctx, 0, 8, tab_reg);
// check to make sure read was successful
if (rc == -1) {
    fprintf(stderr, "%s\n", modbus_strerror(errno));
    return -1;
}
// i'm guessing on this one, but convert a bytes vale into an integer... probably?
//for (i=0; i < rc; i++) {
//    printf("reg[%d]=%d (0x%X)\n", i, tab_reg[i], tab_reg[i]);
//}
printf("h1=%.1f  ",modbus_get_float(&(tab_reg[0])));
printf("t1=%.1f  ",modbus_get_float(&(tab_reg[2])));
printf("h2=%.1f  ",modbus_get_float(&(tab_reg[4])));
printf("t2=%.1f\n",modbus_get_float(&(tab_reg[6])));
// close port and free memory
modbus_close(ctx);
modbus_free(ctx);
return 0;
}