function basename(file) {
	sub(".*/", "", file)
	n = split(file, array, ".")
	return array[1] 
}

/>/ {
	sub(">", "", $0)
	bn = basename(FILENAME)
	print ">" bn, $0;
}

$0 !~ />/ {print $0}
