#include "gcrypt_aux.h"

#include <gcrypt.h>

#include <string.h>

#define FAILURE 0
#define SUCCESS 1

#define NO_ERROR 0
#define VERSION_ERROR 1
#define MEMORY_ERROR 2
#define CIPHER_ERROR 3
#define DATA_ERROR 4

#define CLEAR_ERRORS setErrorInfo(NO_ERROR, NO_ERROR)
/***********************************************************
 * Static variables
 ***********************************************************/
static int g_initCalled = 0;
static const char* g_errorMessage = NULL;

static const char *const g_versionErrorMsg = 
    "Invalid library version";
static const char *const g_memoryErrorMsg = 
    "Cannot allocate memory";
static const char *const g_cipherErrorMsg = 
    "Invalid cipher handle";
static const char *const g_dataErrorMsg =
    "Invalid data (NULL)";

struct Cipher
{
    /**
     * \brief
     * Handle to libgcrypt data structure.
     */
    gcry_cipher_hd_t handle;
    /**
     * \brief
     * Initialization vector used by the algorithm.
     */
    char iv[AES_IV_SIZE];
    /**
     * \brief
     * Key used by the algorithm.
     */
    char key[AES_KEY_SIZE];
};

/***********************************************************
 * Static functions
 ***********************************************************/
static const char* getMyErrorMessage(int myErrCode)
{
    switch(myErrCode) {
        case NO_ERROR:
            return NULL;
        case VERSION_ERROR:
            return g_versionErrorMsg;
        case MEMORY_ERROR:
            return g_memoryErrorMsg;
        case CIPHER_ERROR:
            return g_cipherErrorMsg;
        case DATA_ERROR:
            return g_dataErrorMsg;
    }
}

static void setErrorInfo(gcry_error_t libErrCode, 
                int myErrCode)
{
    g_errorMessage = (libErrCode) ? 
        gcry_strerror(libErrCode) : 
        getMyErrorMessage(myErrCode);
}

static int initLibrary()
{
    if (!gcry_check_version(GCRYPT_VERSION)) {
        return FAILURE;
    }

    gcry_control(GCRYCTL_DISABLE_SECMEM, 0);
    gcry_control(GCRYCTL_INITIALIZATION_FINISHED, 0);
    
    return SUCCESS;
}

static gcry_error_t openCipher(Cipher_t* cipher)
{
    gcry_error_t err = 0;

    //open cipher
    err = gcry_cipher_open(&cipher->handle, 
            GCRY_CIPHER_AES256, 
            GCRY_CIPHER_MODE_CBC, 
            0);
    if (err) {
        return err;
    }
    
    //set key
    err = gcry_cipher_setkey(cipher->handle,
            cipher->key,
            AES_KEY_SIZE);
    if (err) {
        return err;
    }

    //set initialization vector
    err = gcry_cipher_setiv(cipher->handle,
            cipher->iv,
            AES_IV_SIZE);
    if (err) {
        return err;
    }
    
    return GPG_ERR_NO_ERROR;
}

static void closeCipher(Cipher_t* cipher)
{
    gcry_cipher_close(cipher->handle);
}

/***********************************************************
 * Public functions
 ***********************************************************/
char* gcrypt_aux_generateKey()
{
    char* key = NULL;
    
    //init gcrypt library
    if (!g_initCalled) {
        if (initLibrary() == FAILURE) {
            setErrorInfo(NO_ERROR, VERSION_ERROR);
            return NULL;
        }

        g_initCalled = 1;
    }

    //allocate memory for the key
    key = malloc(AES_KEY_SIZE * sizeof(char));
    if (key == NULL) {
        setErrorInfo(NO_ERROR, MEMORY_ERROR);
        return NULL;
    }
    
    //generate key
    gcry_randomize(key, 
            AES_KEY_SIZE, 
            GCRY_VERY_STRONG_RANDOM);

    CLEAR_ERRORS;
    return key;
}

char* gcrypt_aux_generateIV()
{
    char* IV = NULL;

    //init gcrypt library
    if (!g_initCalled) {
        if (initLibrary() == FAILURE) {
            setErrorInfo(NO_ERROR, VERSION_ERROR);
            return NULL;
        }

        g_initCalled = 1;
    }

    //allocate memory for initialization vector
    IV = malloc(AES_IV_SIZE * sizeof(char));
    if (IV == NULL) {
        setErrorInfo(NO_ERROR, MEMORY_ERROR);
        return NULL;
    }
    
    //generate random values
    //gcry_randomize(IV, AES_IV_SIZE, GCRY_STRONG_RANDOM);
    gcry_create_nonce(IV, AES_IV_SIZE);

    CLEAR_ERRORS;
    return IV;
}

const char* gcrypt_aux_getErrorMessage()
{
    return g_errorMessage;
}

Cipher_t* gcrypt_aux_makeCipher(const char* key, 
        const char* iv)
{
    Cipher_t* cipher = NULL;
    gcry_error_t err = 0;

    //init library
    if (!g_initCalled) {
        if (initLibrary() == FAILURE) {
            setErrorInfo(NO_ERROR, VERSION_ERROR);
            return NULL;
        }

        g_initCalled = 1;
    }
    
    //alocate memory for cipher structure
    cipher = malloc(sizeof(Cipher_t));
    if (cipher == NULL) {
        setErrorInfo(NO_ERROR, MEMORY_ERROR);
        return NULL;
    }

    //copy key and iv in data structure
    memcpy(cipher->key, key, AES_KEY_SIZE);
    memcpy(cipher->iv, iv, AES_IV_SIZE);
    
    CLEAR_ERRORS;
    return cipher;
}

char* gcrypt_aux_encrypt(Cipher_t* c, 
        const char* data, 
        int dataSize)
{
    char* output = NULL;
    gcry_error_t err = 0;
    
    if (c == NULL) {
        setErrorInfo(NO_ERROR, CIPHER_ERROR);
        return NULL;
    }

    if (data == NULL) {
        setErrorInfo(NO_ERROR, DATA_ERROR);
        return NULL;
    }
    
    //allocate memory for the encrypted message
    output = malloc(dataSize * sizeof(char));
    if (output == NULL) {
        setErrorInfo(NO_ERROR, MEMORY_ERROR);
        return NULL;
    }
    
    //open cipher
    err = openCipher(c);
    if (err) {
        setErrorInfo(err, NO_ERROR);
        return NULL;
    }
    
    //encrypt data
    err = gcry_cipher_encrypt(c->handle,
            output,
            dataSize,
            data,
            dataSize);
    if (err) {
        setErrorInfo(err, NO_ERROR);
        free(output);
        return NULL;
    }
    
    //close cipher
    closeCipher(c);

    CLEAR_ERRORS;
    return output;
}

char* gcrypt_aux_decrypt(Cipher_t* c, 
        const char* data, 
        int dataSize)
{
    char* output = NULL;
    gcry_error_t err = 0;
    
    if (c == NULL) {
        setErrorInfo(NO_ERROR, CIPHER_ERROR);
        return NULL;
    }
    
    if (data == NULL) {
        setErrorInfo(NO_ERROR, DATA_ERROR);
        return NULL;
    }
    
    //allocate memory for the encrypted message
    output = malloc(dataSize * sizeof(char));
    if (output == NULL) {
        setErrorInfo(NO_ERROR, MEMORY_ERROR);
        return NULL;
    }
    
    //open le cipher
    err = openCipher(c);
    if (err) {
        setErrorInfo(err, NO_ERROR);
        return NULL;
    }
    
    //decrypt data
    err = gcry_cipher_decrypt(c->handle,
            output,
            dataSize,
            data,
            dataSize);
    if (err) {
        setErrorInfo(err, NO_ERROR);
        free(output);
        return NULL;
    }
    
    //close cipher
    closeCipher(c);

    CLEAR_ERRORS;
    return output;
}


void gcrypt_aux_destroyCipher(Cipher_t* c)
{
    free(c);
    CLEAR_ERRORS;
}
