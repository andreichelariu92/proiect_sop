#include "gcrypt_aux.h"

#include <gcrypt.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
/*
int main()
{
    // Version check should be the very first call because it
    // makes sure that important subsystems are initialized.
    if (!gcry_check_version (GCRYPT_VERSION)) {
        fputs ("libgcrypt version mismatch\n", stderr);
        exit (2);
    }

    gcry_control (GCRYCTL_INIT_SECMEM, 16384, 0);

    gcry_control (GCRYCTL_INITIALIZATION_FINISHED, 0);

    printf("Library has been initialized correctly\n");
    
    //generate random key
    char key[32];
    gcry_randomize(key, 32, GCRY_STRONG_RANDOM);

    //generate inversion vector
    char inversionVector[16];
    gcry_randomize(inversionVector, 16, GCRY_STRONG_RANDOM);
    
    //create cypher
    gcry_cipher_hd_t aesHandle;
    gcry_error_t err = 0;
    err = gcry_cipher_open(&aesHandle, GCRY_CIPHER_AES256, GCRY_CIPHER_MODE_CBC, 0);
    if (err) {
        printf("Error creating AES handle\n");
        exit(3);
    }

    //set key
    err = gcry_cipher_setkey(aesHandle, key, 32);
    if (err) {
        printf("Error setting key\n");
        exit(4);
    }
    
    //set inversion vector
    err = gcry_cipher_setiv(aesHandle,inversionVector, 16);
    if (err) {
        printf("Error setting inversion vector\n");
        exit(5);
    }
    
    //encrypt le message
    char message[16] = "Ana are raie   ";
    message[15] = '\0';
    //TODO: ANdrei: Remove
    printf("Sizeof message: %d\n", strlen(message));

    char encryptedMessage[16];
    err = gcry_cipher_encrypt(aesHandle, encryptedMessage, 16, message, 16);
    if (err) {
        printf("Error encrypting message %s\n", gcry_strerror(err));
        exit(6);
    } else {
        printf("Encrypted message: ");
        int idx = 0;
        for (idx = 0; idx < 16; idx++) {
            printf("%c", encryptedMessage[idx]);
        }
        printf("\n");
    }
    
    gcry_cipher_close(aesHandle);
    
    gcry_cipher_open(&aesHandle, GCRY_CIPHER_AES256, GCRY_CIPHER_MODE_CBC, 0);
    gcry_cipher_setkey(aesHandle, key, 32);
    gcry_cipher_setiv(aesHandle, inversionVector, 16);

    //decrypt le message
    char decryptedMessage[16];
    err = gcry_cipher_decrypt(aesHandle, decryptedMessage, 16, encryptedMessage, 16);
    if (err) {
        printf("Error decrypting message %s\n", gcry_strerror(err));
        exit(7);
    }
    
    decryptedMessage[15] = '\0';
    printf("Decrypted message: ");
    int idx = 0;
    for (idx = 0; idx < 16; ++idx) {
        printf("%c", decryptedMessage[idx]);
    }
    printf("\n");

    return 0;
}
*/
void testEncrypt(char* key, char* iv)
{
    //create cypher
    gcry_cipher_hd_t aesHandle;
    gcry_error_t err = 0;
    err = gcry_cipher_open(&aesHandle, 
            GCRY_CIPHER_AES256, 
            GCRY_CIPHER_MODE_CBC, 
            0);
    if (err) {
        printf("Error creating AES handle\n");
        exit(3);
    }

    //set key
    err = gcry_cipher_setkey(aesHandle, key, 32);
    if (err) {
        printf("Error setting key\n");
        exit(4);
    }
    
    //set inversion vector
    err = gcry_cipher_setiv(aesHandle, iv, 16);
    if (err) {
        printf("Error setting inversion vector\n");
        exit(5);
    }
    
    //encrypt le message
    char message[16] = "Ana are raie   ";
    message[15] = '\0';
    //TODO: ANdrei: Remove
    printf("Sizeof message: %d\n", strlen(message));

    char encryptedMessage[16];
    err = gcry_cipher_encrypt(aesHandle, 
            encryptedMessage, 
            16, 
            message, 
            16);
    if (err) {
        printf("Error encrypting message %s\n", 
                gcry_strerror(err));
        exit(6);
    } else {
        printf("Encrypted message: ");
        int idx = 0;
        for (idx = 0; idx < 16; idx++) {
            printf("%d  ", encryptedMessage[idx]);
        }
        printf("\n");
    }
    
    gcry_cipher_close(aesHandle);
    gcry_cipher_open(&aesHandle, 
            GCRY_CIPHER_AES256, 
            GCRY_CIPHER_MODE_CBC, 
            0);
    gcry_cipher_setkey(aesHandle, key, 32);
    gcry_cipher_setiv(aesHandle, iv, 16);


    //decrypt le message
    char decryptedMessage[16];
    err = gcry_cipher_decrypt(aesHandle, 
            decryptedMessage, 
            16, 
            encryptedMessage, 
            16);
    if (err) {
        printf("Error decrypting message %s\n", 
                gcry_strerror(err));
        exit(7);
    }
    
    decryptedMessage[15] = '\0';
    printf("Decrypted message: ");
    int idx = 0;
    for (idx = 0; idx < 16; ++idx) {
        printf("%c  ", decryptedMessage[idx]);
    }
    printf("\n");
}

char* paddMessage(char* msg, int msgLen)
{
    int padLen = AES_BLOCK_SIZE - (msgLen % AES_BLOCK_SIZE);
    if (padLen == 0) {
        return msg;
    }

    char* output = NULL;
    output = malloc(msgLen + padLen);
    strcpy(output, msg);

    int padIdx = msgLen - 1;
    for (; padIdx < msgLen + padLen - 1; ++padIdx) {
        output[padIdx] = '~';
    }
    output[padIdx] = '\0';

    return output;
}

int main()
{

    char* key = gcrypt_aux_generateKey();
    if (key == NULL) {
        printf("Error: %s\n", gcrypt_aux_getErrorMessage());
        return 1;
    }

    char* iv = gcrypt_aux_generateIV();
    if (iv == NULL) {
        printf("Error: %s\n", gcrypt_aux_getErrorMessage());
        return 1;
    }

    testEncrypt(key, iv);

    Cipher_t* cipher = gcrypt_aux_makeCipher(key, iv);
    if (cipher == NULL) {
        printf("Error: %s\n", gcrypt_aux_getErrorMessage());
        return 1;
    }
    
    char data[] = "Dimineata cand ma scol, fac flotari in cap";
    char* paddedData = paddMessage(data, strlen(data) + 1);
    const int dataLen = strlen(paddedData) + 1;
    char* encryptedData = gcrypt_aux_encrypt(cipher, 
                            paddedData, 
                            dataLen);
    if (encryptedData == NULL) {
        printf("Error: %s\n", gcrypt_aux_getErrorMessage());
        return 1;
    }
    
    printf("Encrypted message: ");
    int dataIdx = 0;
    for (; dataIdx < dataLen; ++dataIdx) {
        printf("%d  ", encryptedData[dataIdx]);
    }
    printf("\n");

    char* decryptedMessage = gcrypt_aux_decrypt(cipher,
                                encryptedData,
                                dataLen);

    printf("Decrypted message: ");
    for (dataIdx = 0; dataIdx < dataLen; ++dataIdx) {
        printf("%c  ", decryptedMessage[dataIdx]);
    }
    printf("\n");

    gcrypt_aux_destroy_cipher(cipher);
    return 0;
}
