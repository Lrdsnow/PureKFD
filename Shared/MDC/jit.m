#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <inttypes.h>
int callps() {
    char *address = "127.0.0.1";
    int port = 24602;
    
    
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server;
    server.sin_addr.s_addr = inet_addr(address);
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    connect(sock, (struct sockaddr *)&server, sizeof(server));
    close(sock);
    return 0;
}

int jit(int argc, char *argv[]) {
    // Define the address and port of the LLDB server
    char *address = "127.0.0.1";
    int port = 24601;

//    pid_t pid = 9845;
 pid_t pid = atoi(argv[1]);

    // Create a socket and connect to the LLDB server
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server;
    server.sin_addr.s_addr = inet_addr(address);
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    connect(sock, (struct sockaddr *)&server, sizeof(server));

    // Send the vAttach packet to the LLDB server
    char packet[256];
//    snprintf(packet, 256, "vAttach;pid:%d", getpid());
snprintf(packet, 256, "$QStartNoAckMode#b0");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "+");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qSupported:xmlRegisters=i386,arm,mips,arc;multiprocess+;fork-events+;vfork-events+#2e");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$QEnableCompression:type:lzfse;#bf");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$QThreadSuffixSupported#e4");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$QListThreadsInStopReply#21");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$vCont?#49");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qVAttachOrWaitSupported#38");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$QEnableErrorStrings#8c");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qHostInfo#9b");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qProcessInfo#dc");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qC#b4");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qfThreadInfo#bb");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$qProcessInfo#dc");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$vAttach;%" PRIx64 "#d4", (uint64_t)pid);
   send(sock, packet, strlen(packet), 0);
//sleep(2);
/*snprintf(packet, 256, "$z0,1ce6fc0f8,4#fc");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$z0,1f2bff078,4#cc");
   send(sock, packet, strlen(packet), 0);
*/
snprintf(packet, 256, "$D#44");
   send(sock, packet, strlen(packet), 0);

snprintf(packet, 256, "$k#6b");
   send(sock, packet, strlen(packet), 0);
// Close the socket
    close(sock);

    return 0;
}
