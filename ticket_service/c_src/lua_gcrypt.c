#include "gcrypt_aux.h"

#include <lua.h>
#include <lauxlib.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
/*
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

    printf("Test lua: %d\n", LUA_OK);
    return 0;
}
*/

static int generateKey(lua_State* L)
{
    char* key = gcrypt_aux_generateKey();
    if (key == NULL) {
        return luaL_error(L, "Error generating AES256 key");
    }

    lua_pushlstring(L, key, AES_KEY_SIZE);

    free(key);
    return 1;
}

static int generateIV(lua_State* L)
{
    char* iv = gcrypt_aux_generateIV();
    if (iv == NULL) {
        return luaL_error(L, "Error generating init vector for AES256");
    }

    lua_pushlstring(L, iv, AES_IV_SIZE);

    free(iv);
    return 1;
}

/**
 * \brief
 * Create an AES cipher and returns it to the lua interpreter.
 * Arguments:
 * - key
 * - initialization vector
 * Returns:
 * - cipher as user data
 */
static int makeCipher(lua_State* L)
{
    const char* key = NULL;
    const char* iv = NULL;
    size_t stringSize = 0;
    Cipher_t* cipher;
    Cipher_t** userData = NULL;
    
    //get key
    key = lua_tolstring(L, 1, &stringSize);
    if (key == NULL || stringSize != AES_KEY_SIZE) {
        return luaL_error(L, "Invalid key");
    }
    
    //get IV
    iv = lua_tolstring(L, 2, &stringSize);
    if (iv == NULL || stringSize != AES_IV_SIZE) {
        return luaL_error(L, "Invalid initialization vector");
    }
    
    //create cipher
    cipher = gcrypt_aux_makeCipher(key, iv);
    if (cipher == NULL) {
        return luaL_error(L, gcrypt_aux_getErrorMessage());
    }
    
    //allocate memory in the interpreter for the cipher
    userData = lua_newuserdata(L, sizeof(Cipher_t*));
    if (userData == NULL) {
        gcrypt_aux_destroyCipher(cipher);
        return luaL_error(L, 
                "Cannot allocate memory for userData");
    }
    
    //save cipher
    *userData = cipher;
    //add metatable (for OOP methods)
    luaL_getmetatable(L, "lua_gcrypt_cipher"); //metatable is on top (-1)
    lua_setmetatable(L, -2); //userdata is bellow (-2)
    
    //TODO: Andrei: Find logging mechanism
    printf("Cipher created successfully\n");

    return 1;
}
/**
 * \brief
 * Encrypt the buffer using AES256 in CBC mode.
 * Arguments (from lua):
 * - cipher
 * - data to be encrypted
 * Result:
 * - encrypted data
 */
static int encrypt(lua_State* L)
{
    Cipher_t** cipherAddr = NULL;
    const char* data = NULL;
    size_t dataSize = 0;
    char* encryptedData = NULL;
    
    //get cipher
    cipherAddr = luaL_checkudata(L, 1, "lua_gcrypt_cipher");
    if (cipherAddr == NULL) {
        return luaL_error(L, "Invalid cipher");
    }
    
    //get the data to encrypt
    data = lua_tolstring(L, 2, &dataSize);
    if (data == NULL) {
        return luaL_error(L, "Invalid data to encrypt");
    }
    
    //encrypt le data
    encryptedData = gcrypt_aux_encrypt(*cipherAddr,
                        data,
                        dataSize);
    if (encryptedData == NULL) {
        return luaL_error(L,
                gcrypt_aux_getErrorMessage());
    }
    
    //put the encrypted data in the interpreter
    lua_pushlstring(L, encryptedData, dataSize);

    free(encryptedData);
    return 1;
}

/**
 * \brief
 * Decrypt the buffer given as parameter
 * Arguments (from lua):
 * - cipher
 * - buffer
 * Results (to lua):
 * - the decrypted buffer
 */
static int decrypt(lua_State* L)
{
    Cipher_t** cipherAddr = NULL;
    const char* data = NULL;
    size_t dataSize = 0;
    char* decryptedData = NULL;

    //get cipher
    cipherAddr = luaL_checkudata(L, 1, "lua_gcrypt_cipher");
    if (cipherAddr == NULL) {
        return luaL_error(L, "Invalid cipher");
    }

    //get data to decrypt
    data = lua_tolstring(L, 2, &dataSize);
    if (data == NULL) {
        return luaL_error(L, "Invalid data to decrypt");
    }

    //decrypt le data
    decryptedData = gcrypt_aux_decrypt(*cipherAddr,
                        data,
                        dataSize);
    if (decryptedData == NULL) {
        return luaL_error(L, gcrypt_aux_getErrorMessage());
    }

    //give data to lua
    lua_pushlstring(L, decryptedData, dataSize);

    free(decryptedData);
    return 1;
}

/**
 * \brief
 * Function called by the garbage collector to destroy the cipher.
 */
static int destroyCipher(lua_State* L)
{
    Cipher_t** cipherAddr = NULL;

    //get cipher from lua
    cipherAddr = lua_touserdata(L, 1);
    gcrypt_aux_destroyCipher(*cipherAddr);

    //TODO: Andrei: find logging mechanism
    printf("Cipher destroyed successfully\n");

    return 0;
}

static const luaL_Reg lua_gcrypt[] = {
    {"generateKey", generateKey},
    {"generateIV", generateIV},
    {"makeCipher", makeCipher},
    {NULL, NULL}
};

static const luaL_Reg cipherMethods[] = {
    {"encrypt", encrypt},
    {"decrypt", decrypt},
    {NULL, NULL}
};

int luaopen_lua_gcrypt(lua_State* L)
{
    //create metatable
    luaL_newmetatable(L, "lua_gcrypt_cipher");

    //asign the metatable as __index variable
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");

    //assign the function called by the garbage collector
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, destroyCipher);
    lua_settable(L, -3);

    //set the cipher methods to the metatable
    luaL_setfuncs(L, cipherMethods, 0);
    
    //Create a table with the public functions of the module
    //and leave the table on top of the stack.
    luaL_newlib(L, lua_gcrypt);
    return 1;
}
