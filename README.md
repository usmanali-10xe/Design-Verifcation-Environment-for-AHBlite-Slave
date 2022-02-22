# Design-Verifcation-Environment-for-AHBlite-Slave
Design Verification Environment is used to check the functional correctness of the Design Under Test (DUT) by generating and driving a predefined input sequence to a design, capturing the design output and comparing with-respect-to expected output. Verification environment is a group of classes or components. where each component is performing a specific operation. i.e, generating stimulus, driving, monitoring, etc. and those classes will be named based on the operation.

Following are the key components of a design verification environment:
- **Transaction**
The Transaction class is used as a way of communication between Generator-Driver and
Monitor-Scoreboard. Fields/Signals required to generate the stimulus are declared in this
class.
- **Interface**
It contains design signals that can be driven or monitored.
- **Generator**
Generates the stimulus (create and randomize the transaction class) and send it to Driver
- **Driver**
Receives the stimulus (transaction) from a generator and drives the packet level data
inside the transaction into the DUT through the interface.
- **Monitor**
Observes the activity on interface signals and converts into packet level data which is
sent to the scoreboard.
- **Scoreboard**
Receives data items from monitors and compares them with expected values. Expected
values can be either golden reference values or generated from the reference model.
- **Environment**
The environment is a container class for grouping all components like generator, driver,
monitor and scoreboard.
- **Test**
The test is responsible for creating the environment and initiating the stimulus driving.
- **Testbench Top**
This is the topmost file, which connects the DUT and Test. It consists of DUT, Test and
interface instances. The interface connects the DUT and Test.
