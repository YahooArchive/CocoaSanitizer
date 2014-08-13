objc$target::-*:entry
/ arg0 != 0x0 /
{
	printf("%u %i %i %08x %s %s\n", timestamp, tid, ustackdepth, arg0, probemod, probefunc);
}
