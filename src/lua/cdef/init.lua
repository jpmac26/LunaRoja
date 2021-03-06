require 'cdef.mgba'

if jit.status() then
    ffi.cdef[[
    void PC_HOOK(int bank, int addr, bool (*callback)());
    ]]
    function PC_HOOK(...)
        return ffi.mgba.PC_HOOK(...)
    end
end

ffi.cdef[[

// std

int chmod(const char *pathname, int mode);
int mkdir(const char *path, int mode);
void *malloc(size_t);
int usleep(unsigned int usec);
size_t clock();
void printf(const char *fmt, ...);
void * memcpy(void *, void *, size_t);
void *memset(void *s, int c, size_t n);
int recv(int sockfd, void *buf, size_t len, int flags);
int send(int sockfd, const void *msg, int len, int flags);
int strncmp ( const char * str1, const char * str2, size_t num );
int memcmp ( const void * ptr1, const void * ptr2, size_t num );
void free(void *);

typedef void FILE;
int fseek_wrapper(FILE *stream, long offset, int whence);
void rewind(FILE *stream);
FILE * fopen ( const char * filename, const char * mode );
size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
int fclose ( FILE * stream );
long int ftell ( FILE * stream );

// stb

typedef unsigned char stbi_uc;
stbi_uc *stbi_load               (char              const *filename,           int *x, int *y, int *comp, int req_comp);
const char *stbi_failure_reason  (void);
void     stbi_image_free      (void *retval_from_stbi_load);
int stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
typedef void stbi_write_func(void *context, void *data, int size);
int stbi_write_png_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const void  *data, int stride_in_bytes);

int stb_vorbis_decode_memory(const uint8_t *mem, int len, int *channels, int *sample_rate, short **output);

// sha256

typedef struct SHA256_CTX {
    unsigned char data[64];
    unsigned int datalen;
    unsigned long long bitlen;
    unsigned char state[8];
} SHA256_CTX;
void sha256_init(SHA256_CTX *ctx);
void sha256_update(SHA256_CTX *ctx, const unsigned char data[], size_t len);
void sha256_final(SHA256_CTX *ctx, unsigned char hash[]);

// my stuff

const char *lr_net_error;
int server_start(int port);
int server_listen(int listenfd);
void net_init();

int client_start(const char *ip, const char *port);
bool client_is_connected(int fd);

int closesocket(int fd);
int gethostname(const char *, size_t);


bool tilecopy ( uint8_t *out, int outw, int outh,
                int outx,     int outy,
                uint8_t **in,  int inw, int inh
              );

bool lovecopy(uint8_t *out, uint8_t *in, int size);
bool dumbcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, int stride);
bool dumbcopyaf(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, uint8_t invis, bool flip);
bool alphacopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh);
bool purealphacopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh);
bool scalecopy(uint8_t *out, uint8_t *in, int width, int height, int scale);
bool mgbacopy(uint8_t *out, int outw, int outh, int outx, int outy,
              uint8_t *in,  int inw,  int inh);

void lastcopy(uint8_t *out, uint8_t *in, int w, int h);
void draw_set_color(uint8_t r, uint8_t g, uint8_t b);
void draw_circle(uint8_t *fb, int fbwidth, int fbheight, float x0, float y0, float radius, bool should_outline);
void draw_rect(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy, float fwidth, float fheight);
bool draw_pixel(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy);
void draw_line(uint8_t *fb, int fbwidth, int fbheight, float x1, float y1, float x2, float y2);
bool untargz(const char *filename, const char *outfolder);

]]

if PLATFORM == 'love' or PLATFORM == 'cmd' then
    require 'cdef.desktop'
end
local f = io.open(LUAPATH..'/plat/'..PLATFORM..'/cdef.lua')
if f then
    f:close()
    require('plat.'..PLATFORM..'.cdef')
end

C = ffi.C
