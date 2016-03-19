/*
   C client for caighdean
   Based on:
      http://stackoverflow.com/questions/22077802/
      http://stackoverflow.com/questions/5842471/
*/

#include <stdio.h> /* printf, sprintf */
#include <stdlib.h> /* exit, atoi, malloc, free */
#include <unistd.h> /* read, write, close */
#include <string.h> /* memcpy, memset */
#include <sys/socket.h> /* socket, connect */
#include <netinet/in.h> /* struct sockaddr_in, struct sockaddr */
#include <netdb.h> /* struct hostent, gethostbyname */

void error(const char *msg) { perror(msg); exit(1); }

/*
   pass a pointer to first char *after* opening double quote,
   and this returns pointer to char *after* closing double quote
*/
char* print_json_string(char* j) {
    char buf[1024];
    int i=0;
    while (*j != '"') {
        if (*j == '\\') j++;
        buf[i]=*j;
        i++; j++;
    }
    buf[i]='\0';
    printf("%s", buf);
    j++;
    return j;
} 

void parse_json(char* j) {
    while (isspace(*j)) j++;
    if (*j != '[') error("Malformed JSON.");
    j++;
    while (isspace(*j)) j++;
    while (*j == '[') {
        j++;
        while (isspace(*j)) j++;
        if (*j != '"') error("Malformed JSON.");
        j++;
        j = print_json_string(j);
        printf(" => ");
        while (isspace(*j)) j++;
        if (*j != ',') error("Malformed JSON.");
        j++;
        while (isspace(*j)) j++;
        if (*j != '"') error("Malformed JSON.");
        j++;
        j = print_json_string(j);
        printf("\n");
        while (isspace(*j)) j++;
        if (*j != ']') error("Malformed JSON.");
        j++;
        while (isspace(*j)) j++;
        if (*j == ']') break;
        if (*j != ',') error("Malformed JSON.");
        j++;
        while (isspace(*j)) j++;
    }
}


char *url_encode( unsigned char *s, char *enc){

    char html5[256] = {0};
    int i;
    for (i = 0; i < 256; i++){
        html5[i] = isalnum( i) || i == '*' || i == '-' || i == '.' || i == '_' ? i : (i == ' ') ? '+' : 0;
    }

    for (; *s; s++){

        if (html5[*s]) sprintf( enc, "%c", html5[*s]);
        else sprintf( enc, "%%%02X", *s);
        while (*++enc);
    }

    return( enc);
}

void request_and_response(char* foinse, char* buffer, char* json) {

    /* first where are we going to send it? */
    int portno = 80;
    char *host = "borel.slu.edu";
    char *path = "/cgi-bin/seirbhis3.cgi";
    char *header = "Content-Type: application/x-www-form-urlencoded";

    struct hostent *server;
    struct sockaddr_in serv_addr;
    int sockfd, bytes, sent, received, total, message_size;
    char *body, *message, response[32768], teacs[32768];

    url_encode(buffer, teacs); 

    /* How big is the message? Just for the malloc, Ok to overestimate*/
    message_size=0;
    message_size+=strlen("POST %s HTTP/1.0\r\n");
    message_size+=strlen(path);
    message_size+=strlen(header)+strlen("\r\n");
    message_size+=strlen("Content-Length: %d\r\n")+10;  /* wiggle room if big */
    message_size+=strlen("\r\n");
    message_size+=strlen("foinse=xx&teacs="); /* body */
    message_size+=strlen(teacs);

    /* allocate space for the message */
    message=malloc(message_size);

    sprintf(message,"POST %s HTTP/1.0\r\n", path);
    strcat(message,header); strcat(message,"\r\n");
    sprintf(message+strlen(message),"Content-Length: %d\r\n",(int) (strlen("foinse=xx&teacs=")+strlen(teacs)));
    strcat(message,"\r\n");                                /* blank line     */
    strcat(message,"foinse=");
    strcat(message,foinse);
    strcat(message,"&teacs=");
    strcat(message,teacs);

    /* What are we going to send? */
    /* printf("Request:\n%s\n",message); */

    /* create the socket */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) error("ERROR opening socket");

    /* lookup the ip address */
    server = gethostbyname(host);
    if (server == NULL) error("ERROR, no such host");

    /* fill in the structure */
    memset(&serv_addr,0,sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(portno);
    memcpy(&serv_addr.sin_addr.s_addr,server->h_addr,server->h_length);

    /* connect the socket */
    if (connect(sockfd,(struct sockaddr *)&serv_addr,sizeof(serv_addr)) < 0)
        error("ERROR connecting");

    /* send the request */
    total = strlen(message);
    sent = 0;
    do {
        bytes = write(sockfd,message+sent,total-sent);
        if (bytes < 0)
            error("ERROR writing message to socket");
        if (bytes == 0)
            break;
        sent+=bytes;
    } while (sent < total);

    /* receive the response */
    memset(response,0,sizeof(response));
    total = sizeof(response)-1;
    received = 0;
    do {
        bytes = read(sockfd,response+received,total-received);
        if (bytes < 0)
            error("ERROR reading response from socket");
        if (bytes == 0)
            break;
        received+=bytes;
    } while (received < total);

    if (received == total)
        error("ERROR storing complete response from socket");

    /* close the socket */
    close(sockfd);

    /* process response */
    /* printf("Response:\n%s\n",response); */

    body = strstr(response, "\r\n\r\n");
    if (body == NULL)
        error("Malformed HTTP response");
    body += 4;
    strcpy(json, body);

    free(message);
}

int main(int argc,char *argv[])
{
    int i;
    char json[32768], buffer[32768];

    if (argc < 2) { puts("Usage: ./a.out [ga|gd|gv]"); exit(1); }
    read(STDIN_FILENO, buffer, 32768);

    request_and_response(argv[1], buffer, json);

    /* parse and print result in same format as other clients */
    parse_json(json);

    return 0;
}
