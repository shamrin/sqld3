all:
	echo "/* Parser generated by language.js (see Makefile) */" > sql.js
	language -g sql.language >> sql.js
