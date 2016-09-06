XACTBlue
========

This project is a fork of the original "Blueshell" project developed at the University of York.
It is intended to help alleviate some of the original complexity associated with creating board
support packages etc by instead wrapping each component as an IP-XACT core, then using
Vivado, or another high level integration tool, as the system integrator.

This project is very much a work-in-progress.


Integrated Bluetiles Cores
--------------------------
* **Bluetiles Router**: This is the "standard" Bluetiles router. This routes 32-bit packets around a manhattan grid network.
* **Bluetiles AXIS**: Bridge between Bluetiles and an AXI4-Stream periperal.
* **Bluetiles Condenser**: "Condenses" a set of Bluetiles inputs down to a single BLuetiles input. There are two variants of this, one for condensing "client" interfaces and one for "server" interfaces. They work in the exact same manner.
* **Bluetiles Pingpong**: Simple Bluetiles client which simply responds with the data it was given.
* **Bluetiles Inspector**: Core used to communicate with the host computer. This is used on non-Zynq platforms to communicate with the board over some communication means.

Integrated Bluetree Cores
-------------------------
* **Bluetree Mux2**: Simple 2-input Bluetree multiplexer.
* **Bluetree To AXI and vice versa**: Bridges between Bluetree and AXI.

