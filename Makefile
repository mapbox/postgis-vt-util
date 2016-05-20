README.md: postgis-vt-util.sql
	sed -n -i'' -e '1,/<!-- DO NOT EDIT BELOW/p' $@
	grep -Pzo '(?s)\/[*]+.*?[*]+\/' postgis-vt-util.sql | sed 's/^[\/\*]\+.*/\n/' >> $@

postgis-vt-util.sql: src/Bounds.sql src/CleanInt.sql src/CleanNumeric.sql src/LabelGrid.sql src/LargestPart.sql src/LineLabel.sql src/MakeArc.sql src/MercBuffer.sql src/MercDWithin.sql src/MercLength.sql src/OrientedEnvelope.sql src/Sieve.sql src/SmartShrink.sql src/TileBBox.sql src/ToPoint.sql src/ZRes.sql src/Z.sql
	cat $^ > $@
