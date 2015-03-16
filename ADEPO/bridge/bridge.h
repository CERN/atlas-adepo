#ifndef BRIDGE_H
#define BRIDGE_H

#define ADEPO_UNSET "Unset"
#define ADEPO_INIT "Init"
#define ADEPO_IDLE "Idle"
#define ADEPO_RUN "Run"
#define ADEPO_STOP "Stop"
#define ADEPO_WAITING "Waiting"
#define ADEPO_CALCULATING "Calculating"

#define LWDAQ_UNSET "Unset"
#define LWDAQ_INIT "Init"
#define LWDAQ_IDLE "Idle"
#define LWDAQ_RUN "Run"
#define LWDAQ_STOP "Stop"
// last three states are set by LWDAQ Acquisifier

class Bridge
{
public:
    Bridge() {};
    ~Bridge() {};
};

#endif // BRIDGE_H
