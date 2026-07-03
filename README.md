# Serdes General Information
This repository includes a synthesizeable Serdes module, as well as verifying it works properly.

A Serdes is short-hand for Serializer and Deserializer. This module receives parallel data, and serializes it into single bit outputs.
Then it sends those singular bits to a deserializer which reconstructs the original parallel data.

The point of such module, is that parellel data cannot be transferred efficiently over long distances at sufficient speeds high speeds. 
Serdes modules are used in monitors and GPUs. Just to put it into perspective (Some unnecessary math to make a point):

A standard 1920x1080 monitor has 2,703,600 pixels. Each pixel, is made up of 3 bytes/sub-pixels. Giving us 6,220,800 bytes/sub-pixels.
Now, each sub-pixel - reg, green, blue. Is actually 8 bits, meaning it varies in brights from 0 to 255. We can multiply 6,220,800 * 8
to convert from bytes to bits we get 49 766 400. This is how many bits a standard monitor can display. Now imagine need a cable with a 
dedicated wire for each bit.

Since parallel data means having multiple wires in a single cable, this not only increases the cost of cables used in designs,
it increase the parasitic capcitance between the wires, which at high speeds (like the ones used in this design) can lead to corrupted data.

The design has the following port list for the serializer and deserializer:
``` verilog
module serializer(
	input sClk,
	input pClk,
	input rst,
	input [7:0] pDataIn,
	output reg sDataOut
);

module deserializer(
	input sDataIn,
	input sClk,
	input pClk,
	input rst,
	output reg [7:0] pDataOut
);
```

# Goal of the assignment
The serdes has two external clocks, the `sClk`, and `pClk`. To avoid clock domain crossing, all clocks (excluding sClk) are derivative of the fastest clock (the sClk).
In the assignment the sClk works at 8.33GHz. The assignment required 3 stages of serialization and deserialization. Which prevents us from using a 8:1 and 1:8 shift register.

Additionally using the fastest clock to generate all other clocks has the advantage of not require a PLL module. 
A PLL module itself would increase the difficulty of this task exponentially.

# Designing the serializer and how it works
The serializer is designed to serializer from the least significant bit to the most significant bit, 
it works by first passing 8 bits of parrelel data into a register, which works on our pClk. Which is 8 time slower than the sClk, or around 1GHz~. 
It then passes the 4 most significant bits, and the 4 least significant bits to a MUX, which is controlled by a sClk that's divded by 4. This sClk/4
is internally generated through clock frequency dividers. We then pass those 4 bits to a 4-bit register. This register is also controlled by sClk/4. 
The MUX sends data at the posedge and negedge of the sClk/4 signal, but the register only updates on the positive edge. This is how we always ensure data at every sClk further in the pipeline.
We then pass the 4-bit register's data to another MUX, which controlled by sClk/2. Then we store the data into a 2 bit register.
Exactly the same process as in the 8-to-4 reduction repeats.

# Verification process
If you want to see how we verify the serializer you can checkout the `ser_test_bench.v`. To keep this brief:
We first pass the parallel data to a registers, before it enters the serializer. We add a shift register, which simulates the deserializer which is supposed to assemble the data.
Since the serializer has 3 stages of serialization, the registers add delay to the design. I have intentionally added appropriate delay to the input data, to compare it to the output.
In the simulations I saw that I need to way 2 pClk after the reset signal in order to receive data on the sData output. 

# Designing the deserializer
The deserializer is designed reassemble the data from the serializer from LSB to MSB. Designing the DES requires timing diagrams which I couldn't include in this repo.
Since the first bit the deserializer receives is actually the least significant bit at the output, the output we see should be a mirror image of the input. 

# Mirrored output explanation.
Example input: 1000_1101 would give us an ouput of 1011_0001. This assuming you pass the data in the following manner: 1-0-0-0 1-1-0-1.
This makes the first 4 bits, the 4 least significant bits, so 1101_1000. Then of course we look at the 2 most significant bits of the 4 least significant bits.
In other words we look at the 10 and 00 of 1000. We know that the 2 MS bits, are actually our LS bits. So then we get 0010. Lastly, we look at the 0010 one more,
we look at the MS bit of our 2 LS bits. So, we look at the 1 in 10. We know 1 is actually our LSB, so we flip around those two bits, and we get - 0001. 
We don't have to rearrange 00, since they are the same bit. You can also perform this logic on 1011. You will get 1101. Combining that with 0001 you get a mirrored output.

# Deserializer Verification
Verifying the deserializer design requires a similar process we took in verifying the serializer. Firstly, we pass the serial data to the deserialzier and a shift register.
As established previously the shift register should mimic the behaviour of the deserializer. It is important to mention, that in some designs
The serializer part of the design and deserializer might not have the same reset signal. This means we can't guarantee when the deserializer will start taking data from the SER.
This is important, because it shifts our expected output a few bits to the left/right. To catch this shifting of the output, we add another shift register.
This time, it is twice the width of the DES output. This ensure that any shift is caught. 

Once both designes were verified, we connect the designs, and use a combination of the two verification methods to verify the entire SERDES module.

# Serdes verification
We create a register that holds our parallel date, before the SER. We delay that data as long as necessary. At the end of the DES we add a shift register with twice the width
of the DES output to catch any shifting. What our shift is, and what our timing for the check is based on the timing diagram of the simulation. We setup all necessary logic
(counters, combination logic, sequential logic) to ensure we check the delayed pData and the appropriate section of the shift register.

If everything works as expected, the pData should exactly match 8 bits of the shift register. You just need to make sure you're comparing the correct 8 bits.
