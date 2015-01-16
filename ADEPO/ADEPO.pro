TEMPLATE = subdirs
SUBDIRS = common bridge server client

XXX = client adepo

common.file = common/common.pro
server.file = server/server.pro
client.file = client/client.pro
bridge.file = bridge/bridge.pro
adepo.file = adepo/adepo.pro

OTHER_FILES = \
    ../TODO

