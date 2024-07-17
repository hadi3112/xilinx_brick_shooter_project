module top(
	
	input wire clk,			//master clock = 100MHz
	//input wire clr,			//right-most pushbutton for reset
	input wire sw,				// first switch
	input wire btnS, 			// middle button, move right
	input wire btnU,			// up button, shoot
	input wire btnL,			// left button, move left
	input wire btnR, 
	
	output wire [2:0] red,	//red vga output - 3 bits
	output wire [2:0] green,//green vga output - 3 bits
	output wire [1:0] blue,	//blue vga output - 2 bits
	output wire hsync,		//horizontal sync out
	output wire vsync			//vertical sync out
	);

// VGA display clock interconnect
wire pix_en;
wire game_clk;

	reg rst;
	reg rst_ff;
 
	always @(posedge clk /*or posedge clr*/) begin
	//	if (clr) begin
	//		{rst,rst_ff} <= 2'b11;
	//	end
		// else begin
			{rst,rst_ff} <= {rst_ff,1'b0};
		//end
	end


// generate 7-segment clock & display clock
clockdiv div(
	.clk(clk),
	.rst(rst),
	.pix_en(pix_en),
	.game_clk(game_clk)
	);

// VGA controller
vga640x480 U3(
	.pix_en(pix_en),
	.game_clk(game_clk),
	.clk(clk),
	.rst(rst),
	.btnS(btnS),
	.btnU(btnU),
	.btnL(btnL),
	.btnR(btnR),
	.hsync(hsync),
	.vsync(vsync),
	.red(red),
	.green(green),
	.blue(blue)
	);
endmodule
