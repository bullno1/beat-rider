#ifndef GST_STUB_H
#define GST_STUB_H

#include <stdint.h>
#include <assert.h>

typedef unsigned char guchar;
typedef int gint;
typedef unsigned int guint;
typedef gint gboolean;
typedef int8_t gint8;
typedef uint8_t guint8;
typedef int16_t gint16;
typedef uint16_t guint16;
typedef int32_t gint32;
typedef uint32_t guint32;
typedef int64_t gint64;
typedef uint64_t guint64;
typedef unsigned long gsize;
typedef float gfloat;
typedef double gdouble;
typedef void* gpointer;

#define FALSE (0)
#define TRUE (!FALSE)

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
#define MAX(X,Y) ((X) > (Y) ? (X) : (Y))
#define G_LIKELY(expr) (expr)
#define G_UNLIKELY(expr) (expr)
#define G_GUINT64_CONSTANT(val) (val##UL)
#define g_new0(type, count) ((type *) g_malloc0 ((unsigned) sizeof (type) * (count)))

/*Define away*/
#define GST_LOG
#define G_GINT64_FORMAT
#define G_GUINT64_FORMAT
#define GST_DEBUG_CATEGORY_EXTERN
#define g_return_if_fail
#define g_assert assert
#define g_return_val_if_fail
#define GST_WARNING
#define GST_DEBUG

gpointer g_malloc0(gsize size);
void g_free(gpointer ptr); 

#endif
