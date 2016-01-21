#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <string.h>
#include <modbus.h>
#include <unistd.h>

#include <sys/select.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define NB_CONNECTION    5

modbus_t *ctx = NULL;
int server_socket = -1;
modbus_mapping_t *mb_mapping;

static void close_sigint(int dummy)
{
    if (server_socket != -1) {
        close(server_socket);
    }
    modbus_free(ctx);
    modbus_mapping_free(mb_mapping);
    exit(dummy);
}

#define ERROR_REG -30000

int16_t ReadParam(char *name, float mtp)
{
	FILE *myfile;
	float val;
	myfile = fopen(name,"r");
	if(myfile == NULL) {
        usleep(100*1000);
	    if(myfile == NULL) {
		    return ERROR_REG;
        }
	}
	if(fscanf(myfile,"%f",&val) != EOF) {
		fclose(myfile);
		return (int16_t)(val*mtp);
	}
	fclose(myfile);
	return ERROR_REG;
}

int16_t ReadParamYesNo(char *name)
{
	FILE *myfile;
	char val[20];
	myfile = fopen(name,"r");
	if(myfile == NULL) {
		return ERROR_REG;
	}
	if(fscanf(myfile,"%s",&val) != EOF) {
		fclose(myfile);
		if(strcmp(val,"Yes") == 0) {
		   return (int16_t)(1);
		}
		else {
		   return 0;
		}
	}
	fclose(myfile);
	return ERROR_REG;
}

int WriteParam(char *name,int16_t reg, float mtp)
{
	FILE *myfile;
	myfile = fopen(name,"w");
	if(myfile == NULL) {
		return -1;
	}
	fprintf(myfile,"%.2f",mtp*((float)(reg)));
	fclose(myfile);
	return 0;
}

int WriteParamI(char *name,int16_t reg, float mtp)
{
	FILE *myfile;
	myfile = fopen(name,"w");
	if(myfile == NULL) {
		return -1;
	}
	fprintf(myfile,"%.0f",mtp*((float)(reg)));
	fclose(myfile);
	return 0;
}

int WriteParamYesNo(char *name,int16_t reg)
{
	FILE *myfile;
	myfile = fopen(name,"w");
	if(myfile == NULL) {
		return -1;
	}
    if(reg > 0)
	    fprintf(myfile,"Yes");
    else
	    fprintf(myfile,"No");
	fclose(myfile);
	return 0;
}


void WriteParams()
{
    WriteParam("/var/data/cfgHstart.dat", mb_mapping->tab_registers[7], 0.01);
    WriteParam("/var/data/cfgHstop.dat", mb_mapping->tab_registers[8], 0.01);
    WriteParamI("/var/data/cfgHwork.dat", mb_mapping->tab_registers[10], 1.0);
    WriteParamYesNo("/var/data/cfgThingspeak.dat", mb_mapping->tab_registers[11]);
    WriteParamI("/var/data/cfgWdog.dat", mb_mapping->tab_registers[12], 1.0);
    WriteParamI("/var/data/cfgVpnChk.dat", mb_mapping->tab_registers[13], 1.0);
    WriteParamI("/var/data/Test.dat", mb_mapping->tab_registers[14], 1.0);
}

void ReadParams()
{
	mb_mapping->tab_registers[0] = ReadParam("/var/data/Hcellar.dat",100.0);
	mb_mapping->tab_registers[1] = ReadParam("/var/data/Tcellar.dat",100.0);
	mb_mapping->tab_registers[2] = ReadParam("/var/data/Hgarage.dat",100.0);
	mb_mapping->tab_registers[3] = ReadParam("/var/data/Tgarage.dat",100.0);
	mb_mapping->tab_registers[4] = ReadParam("/var/data/Tin.dat",100.0);
	mb_mapping->tab_registers[5] = ReadParam("/var/data/HcellarA.dat",100.0);
	mb_mapping->tab_registers[6] = ReadParam("/var/data/HgarageA.dat",100.0);
	mb_mapping->tab_registers[7] = ReadParam("/var/data/cfgHstart.dat",100.0);
	mb_mapping->tab_registers[8] = ReadParam("/var/data/cfgHstop.dat",100.0);
	mb_mapping->tab_registers[9] = ReadParam("/var/data/Fan.dat",1.0);
	mb_mapping->tab_registers[10] = ReadParam("/var/data/cfgHwork.dat",1.0);
	mb_mapping->tab_registers[11] = ReadParamYesNo("/var/data/cfgThingspeak.dat");
	mb_mapping->tab_registers[12] = ReadParam("/var/data/cfgWdog.dat",1.0);
	mb_mapping->tab_registers[13] = ReadParam("/var/data/cfgVpnChk.dat",1.0);
	mb_mapping->tab_registers[14] = ReadParam("/var/data/Test.dat",1.0);
}


int main(void)
{
    uint8_t query[MODBUS_TCP_MAX_ADU_LENGTH];
    int master_socket;
    int rc;
    fd_set refset;
    fd_set rdset;
    /* Maximum file descriptor number */
    int fdmax;

    ctx = modbus_new_tcp("127.0.0.1",502);
    mb_mapping = modbus_mapping_new(0, 0,30, 0);

	if (mb_mapping == NULL) {
        fprintf(stderr, "Failed to allocate the mapping: %s\n",
                modbus_strerror(errno));
        modbus_free(ctx);
        return -1;
    }

    server_socket = modbus_tcp_listen(ctx, NB_CONNECTION);
    
    signal(SIGINT, close_sigint);

    /* Clear the reference set of socket */
    FD_ZERO(&refset);
    /* Add the server socket */
    FD_SET(server_socket, &refset);

    /* Keep track of the max file descriptor */
    fdmax = server_socket;

    for (;;) {
        rdset = refset;
        if (select(fdmax+1, &rdset, NULL, NULL, NULL) == -1) {
            perror("Server select() failure.");
            close_sigint(1);
        }


        /* Run through the existing connections looking for data to be
         * read */
        for (master_socket = 0; master_socket <= fdmax; master_socket++) {
            if (!FD_ISSET(master_socket, &rdset)) {
                continue;
            }
            if (master_socket == server_socket) {
                /* A client is asking a new connection */
                socklen_t addrlen;
                struct sockaddr_in clientaddr;
                int newfd;

                /* Handle new connections */
                addrlen = sizeof(clientaddr);
                memset(&clientaddr, 0, sizeof(clientaddr));
                newfd = accept(server_socket, (struct sockaddr *)&clientaddr, &addrlen);
                if (newfd == -1) {
                    perror("Server accept() error");
                } else {
                    FD_SET(newfd, &refset);
                    if (newfd > fdmax) {
                        /* Keep track of the maximum */
                        fdmax = newfd;
                    }
                    printf("New connection from %s:%d on socket %d\n",
                           inet_ntoa(clientaddr.sin_addr), clientaddr.sin_port, newfd);
                }

            } else {
                modbus_set_socket(ctx, master_socket);
                rc = modbus_receive(ctx, query);
                if (rc > 0) {
					ReadParams();
                    modbus_reply(ctx, query, rc, mb_mapping);
					if(query[7] == 6) {
						WriteParams();
						printf("WriteParams\n");
					}
                } else if (rc == -1) {
                    /* This example server in ended on connection closing or
                     * any errors. */
                    printf("Connection closed on socket %d\n", master_socket);
                    close(master_socket);
                    /* Remove from reference set */
                    FD_CLR(master_socket, &refset);
                    if (master_socket == fdmax) {
                        fdmax--;
                    }
                }
            }
        }
    }
    return 0;
}
