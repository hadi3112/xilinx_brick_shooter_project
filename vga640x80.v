module vga640x480(
	input wire pix_en,		//pixel clock: 25MHz
	input wire game_clk,
	input wire clk,			//100MHz
	input wire rst,			//asynchronous reset
	input wire btnS,
	input wire btnU,
	input wire btnL,
	input wire btnR,
	output wire hsync,		//horizontal sync out
	output wire vsync,		//vertical sync out
	output reg [2:0] red,	//red vga output
	output reg [2:0] green, //green vga output
	output reg [1:0] blue	//blue vga output
	);

// video structure constants
parameter hpixels = 800;
parameter vlines = 521;  
parameter hpulse = 96; 	
parameter vpulse = 2; 	// 
parameter hbp = 144; 	// end of horizontal back porch
parameter hfp = 784; 	// beginning of horizontal front porch
parameter vbp = 31; 		// end of vertical back porch
parameter vfp = 511; 	// beginning of vertical front porch




parameter numbrickss = 5;
parameter winningScore = numbrickss * 10;
parameter topBarPos = 200 + vbp;
parameter leftBarPos = hbp + 200;
parameter rightBarPos = hfp - 200;

integer playerPosY = -70 + vfp;
integer playerPosX = 320 + hbp;
integer bulletPosX = 0;
integer bulletPosY = 0;

integer score = 0;

reg [10:0] bricksPosXArray[0:numbrickss-1];
reg [10:0] bricksPosYArray[0:numbrickss-1];


// For bricks movement.
reg[7:0] bricksTranslationCnt = 0;
reg[12:0] translation = 0;
reg[3:0] deadbrickss = 2;
reg bricksRight = 1;
reg[3:0] bricksSpeed = 'b0110; 




initial
begin
	bricksPosXArray[0] = 200 + hbp;
	bricksPosXArray[1] = 240 + hbp;
	bricksPosXArray[2] = 280 + hbp;
	bricksPosXArray[3] = 200 + hbp;
	bricksPosXArray[4] = 280 + hbp;

	bricksPosYArray[0] = 220 + vbp;
	bricksPosYArray[1] = 220 + vbp;
	bricksPosYArray[2] = 220 + vbp;
	bricksPosYArray[3] = 600;//250 + vbp;
	bricksPosYArray[4] = 600;//250 + vbp;
	
end



// registers for storing the horizontal & vertical counters
reg [9:0] hc;
reg [9:0] vc;

// flags
reg spawnBullet;
reg gameover = 0;


// iterators
reg[6:0] i;
reg[6:0] j;
reg[6:0] k;

always @(posedge clk)
begin
	if(btnU 	&& deadbrickss < numbrickss)
		if(bulletPosY <= topBarPos)
			spawnBullet <= 1;
	else if (bulletPosY > vbp)
		spawnBullet <= 0;
	
	// If brickss touch player then he dies.
	if(bricksPosYArray[0] > playerPosY - 8 && bricksPosYArray[0] < vfp ||
		bricksPosYArray[1] > playerPosY - 8 && bricksPosYArray[1] < vfp ||
	   bricksPosYArray[2] > playerPosY - 8 && bricksPosYArray[2] < vfp || 
	   bricksPosYArray[3] > playerPosY - 8 && bricksPosYArray[3] < vfp ||
	   bricksPosYArray[4] > playerPosY - 8 && bricksPosYArray[4] < vfp)
		gameover <= 1;
	
	// reset condition
	if (rst == 1)
	begin
		hc <= 0;
		vc <= 0;
		spawnBullet <= 0;
		
	end
	else if (pix_en == 1)
	begin
		// keep counting until the end of the line
		if (hc < hpixels - 1)
			hc <= hc + 1;
		else
		begin
			hc <= 0;
			if (vc < vlines - 1)
				vc <= vc + 1;
			else
				vc <= 0;
		end
	end

end

always @(posedge game_clk or posedge spawnBullet)
begin

	if(spawnBullet)
	begin
		bulletPosX <= playerPosX + 9;
		bulletPosY <= playerPosY - 7;
	end 
   else 
	begin
		bricksTranslationCnt <= bricksTranslationCnt + 1;
		if(bricksTranslationCnt == bricksSpeed) //1)
		begin
			if(translation < 150)
				translation <= translation + 1;
			bricksTranslationCnt <= 0;
			for(k = 0; k < numbrickss; k = k + 1)
			begin
				if(translation < 144)
				begin	
					 // Putting this line here makes the synthesis take forever for some reason.
					if(bricksRight)
						bricksPosXArray[k] <= bricksPosXArray[k] + 1;
					else
						bricksPosXArray[k] <= bricksPosXArray[k] - 1;
				end
				else // Move brickss down.
				begin
					translation <= 0;
					bricksRight <= ~bricksRight;
					bricksPosYArray[k] <= bricksPosYArray[k] + 10;
				end
			end
		end
				
		if(btnL && playerPosX != leftBarPos) // Move left.
			playerPosX <= playerPosX - 1;
		if(btnR && playerPosX != rightBarPos - 18) // Move right.
			playerPosX <= playerPosX + 1;
			
		// When player wins, travel upwards.
		if(deadbrickss >= numbrickss)
			playerPosY <= playerPosY - 1;
			
		// Advance to next level once the player reaches the top.
		if(playerPosY < vbp)
		begin
			bricksPosXArray[0] <= 200 + hbp;
			bricksPosXArray[1] <= 240 + hbp;
			bricksPosXArray[2] <= 280 + hbp;
			bricksPosXArray[3] <= 200 + hbp;
			bricksPosXArray[4] <= 280 + hbp;

			bricksPosYArray[0] <= 220 + vbp;
			bricksPosYArray[1] <= 220 + vbp;
			bricksPosYArray[2] <= 220 + vbp;
			bricksPosYArray[3] <= 250 + vbp;
			bricksPosYArray[4] <= 250 + vbp;
			
			playerPosY <= -70 + vfp;
			
			deadbrickss <= 0;
			translation <= 0;
			bricksRight <= 1;
			bricksSpeed <= bricksSpeed >> 1;
		end
			
		if(bulletPosY >= 0)
			bulletPosY <= bulletPosY - 1;
			
		// Kill bricks once it comes into contact with a bullet.
		for(j = 0; j < numbrickss; j = j + 1)
		begin
			if(bulletPosX > bricksPosXArray[j] - 4 && bulletPosX <= bricksPosXArray[j] + 14 &&
					bulletPosY - 8 <= bricksPosYArray[j] && bulletPosY >= bricksPosYArray[j])
			begin
				bricksPosYArray[j] <= 600;
				bulletPosY <= 0;
				bulletPosX <= 0;
				score <= score + 10;
				deadbrickss <= deadbrickss + 1;
			end
		end
	end
end

assign hsync = (hc < hpulse) ? 0:1;
assign vsync = (vc < vpulse) ? 0:1;


always @(*)
begin
	
	// first check if we're within vertical active video range
	if (vc >= vbp && vc < vfp)
	begin
		if(gameover)
		begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b00;
		end
		// Draw purple bars at the sides of the screen.
		else if(hc >= rightBarPos || hc <= leftBarPos)
		begin
			red = 3'b111;
			green = 3'b000;
			blue = 2'b11;
		end
		// Draw bullet.
		else if (hc >= (bulletPosX) && hc < (bulletPosX + 2)
			&& vc >= (bulletPosY - 10) && vc < (bulletPosY))
		begin
			red = 3'b111;
			green = 3'b111;
			blue = 2'b000;
		end
		// Draw player sprite.
		else if (hc >= (playerPosX) && hc < (playerPosX + 18)
				&& vc >= (playerPosY - 7) && vc < (playerPosY))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
		
		else if (hc >= (playerPosX + 7) && hc < (playerPosX + 11)
				&& vc >= (playerPosY - 10) && vc < (playerPosY - 7))
		begin
			red = 3'b000;
			green = 3'b111;
			blue = 2'b00;
		end
		else
		// Draw black.
		begin
			red = 3'b000;
			green = 3'b000;
			blue = 2'b00;
		end
		
		
		
		// Now draw bricks
		for(i = 0; i < numbrickss; i = i + 1)
		begin
				if(hc >= bricksPosXArray[i] && hc < bricksPosXArray[i] + 9 &&
            vc >= bricksPosYArray[i] - 6 && vc < bricksPosYArray[i])
				
				begin
					red = 3'b111;
					green = 3'b111;
					blue = 2'b11;
				end
			end
		
	end
	// we're outside active vertical range so display black
	else
	begin
		red = 0;
		green = 0;
		blue = 0;
	end
	
end

endmodule
