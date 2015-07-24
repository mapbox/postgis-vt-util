README.md: postgis-vt-util.sql
	sed -n -i'' -e '1,/<!-- DO NOT EDIT BELOW/p' $@
	grep -Pzo '(?s)\/[*]+.*?[*]+\/' postgis-vt-util.sql | sed 's/^[\/\* ]\+$$//' >> $@

postgis-vt-util.sql: $(wildcard src/*.sql)
	cat $^ > $@
