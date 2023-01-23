#!/usr/bin/env bash
#
add_disk() {
    # $1 - zone
    # $2 - ip last octet
    # $3 - replication ip last octet
    # $4 - disk name
    swift-ring-builder data/account.builder add r1z$1-192.168.82.$2:6202R192.168.83.$3:6202/$4 100
    swift-ring-builder data/container.builder add r1z$1-192.168.82.$2:6201R192.168.83.$3:6201/$4 100
    swift-ring-builder data/object.builder add r1z$1-192.168.82.$2:6200R192.168.83.$3:6200/$4 100
}

POLICIES="object container account"

#for p in $POLICIES; do
#  swift-ring-builder $p.builder create 14 3 24
#done

# Zone 1
add_disk 1 101 101 vdd1

# Zone 2
add_disk 2 45 15 vdb
#
# Zone 3
add_disk 3 48 72 vdb

# Zone 4
add_disk 4 104 104 vdd1

# Zone 5
add_disk 5 105 105 vdd1

# Zone 6
add_disk 6 106 106 vdd1

# Zone 7
add_disk 7 107 107 vdd1

# Zone 8
add_disk 8 108 108 vdd1


for p in $POLICIES; do
    swift-ring-builder data/$p.builder rebalance
done
