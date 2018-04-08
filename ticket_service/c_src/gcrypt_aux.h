#ifndef gcrypt_aux_INCLUDE_GUARD
#define gcrypt_aux_INCLUDE_GUARD

#define AES_KEY_SIZE 32
#define AES_BLOCK_SIZE 16
#define AES_IV_SIZE 16

/**
 * \brief
 * Generate key for AES 256 algorithm.
 * The memory must be freed by the user.
 * In case of error, NULL is returned.
 * The size of the buffer is 32 bytes.
 */
char* gcrypt_aux_generateKey();

/**
 * \brief
 * Generate initialization vector for CBC mode.
 * THe memory must be freed by the user.
 * In case of error, NULL is returned.
 * The size of the buffer is 16.
 */
char* gcrypt_aux_generateIV();

/**
 * \brief
 * Returns the message of the last error.
 * If there was no error, NULL is return.
 * Do not free this memory!
 */
const char* gcrypt_aux_getErrorMessage();
/**
 * Opaque structure representing an AES cipher.
 * The cipher is used to encrypt / decrypt data.
 * Use gcrypt_aux_destroy_cipher to clear up cipher.
 */
struct Cipher;
typedef struct Cipher Cipher_t;

/**
 * \brief
 * Create an AES256 cypher which uses key and
 * iv (initialization vector) for encryption / decryption.
 * NULL is returned in case of error.
 */
Cipher_t* gcrypt_aux_makeCipher(const char* key, 
            const char* iv);

/**
 * \brief
 * Encrypt the given block of data.
 * The dataSize must be divizible with AES_BLOCK_SIZE
 * In case of error, NULL is returned.
 * The size of the encryted buffer is dataSize.
 *
 */
char* gcrypt_aux_encrypt(Cipher_t* c, 
        const char* data, 
        int dataSize);

/**
 * \brief
 * Decrypt the given block of data.
 * The dataSize must be divizible with AES_BLOCK_SIZE.
 * In case of error, NULL is returned.
 * The size of the decrypted buffer is dataSize.
 */
char* gcrypt_aux_decrypt(Cipher_t* c, 
        const char* data, 
        int dataSize);

/**
 * \brief
 * Destroy the sepcifed Cipher.
 */
void gcrypt_aux_destroyCipher(Cipher_t* c);
#endif
