#include "gst-stub.h"
#include <stdlib.h>
#include <string.h>

gpointer g_malloc0(gsize size)
{
	return memset(malloc(size), 0, size);
}

void g_free(gpointer ptr)
{
	free(ptr);
}
