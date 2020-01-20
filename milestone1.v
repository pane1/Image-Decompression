`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50,                   // 50 MHz clock
		
		////// top level signal
		input logic start,
		output logic done,
		input logic Resetn,
		
		input logic [15:0] SRAM_read_data,
		
		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic we_n
);

//state registers
state_type state;
state_type m1_state;

//registers that will hold U and V values
logic[7:0] sram_data_u[5:0];
logic[7:0] sram_data_v[5:0];

logic[15:0] temp_u;
logic[15:0] temp_v;

//registers for results 
logic[63:0] R_even;
logic[31:0] G_even;
logic[63:0] B_even;
logic[63:0] R_odd;
logic[31:0] G_odd;
logic[63:0] B_odd;

//registers for holding values for operations 
logic[63:0] G_calc;
logic[31:0] G_reduce;

logic[63:0] Y_calc_even;
logic[63:0] Y_calc_odd;
logic[7:0] Y_even;
logic[7:0] Y_odd;

logic[31:0] Ueven_prime;
logic[63:0] Uodd_prime;
logic[31:0] Veven_prime;
logic[63:0] Vodd_prime;
 
logic[31:0] yextend_even;
logic[31:0] yextend_odd;
logic[31:0] m1_res, m2_res, m3_res;
logic[31:0] m1_op1, m1_op2, m2_op1, m2_op2, m3_op1, m3_op2;

//registers that drives the constants to be used in calculations
logic[31:0] a, c, l, m, s;
logic[7:0] y;
logic[31:0] uv;
assign a = 32'd76284;
assign c = 32'd104595;
assign l = -32'd25624;
assign m = -32'd53281;
assign s = 32'd132251;
assign y = 32'd16;
assign uv = 32'd128;

//multipliers
assign m1_res = m1_op1 * m1_op2;
assign m2_res = m2_op1 * m2_op2;
assign m3_res = m3_op1 * m3_op2;

//parameters for offset
parameter U_offset = 38400,
          V_offset = 57600,
          RGB_offset = 146944;

//counters
logic read_uv;
logic[32:0] Y_counter;
logic[32:0] counter;
logic[3:0] lead_out_counter;
logic[32:0] RGB_counter;
logic[7:0] calc;

//flags
logic trans;

always_ff @ (posedge CLOCK_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		state <= S_m1_IDLE;

		we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		read_uv <= 1'b0;
		trans <= 1'b0;
		counter <= 16'd0;
		Y_counter <= 16'd0;
		RGB_counter <= 16'd0;
		lead_out_counter <= 4'd0;
		
		sram_data_u[0] <= 8'd0;
		sram_data_u[1] <= 8'd0;
		sram_data_u[2] <= 8'd0;
		sram_data_u[3] <= 8'd0;
		sram_data_u[4] <= 8'd0;
		sram_data_u[5] <= 8'd0;
		sram_data_v[0] <= 8'd0;
		sram_data_v[1] <= 8'd0;
		sram_data_v[2] <= 8'd0;
		sram_data_v[3] <= 8'd0;
		sram_data_v[4] <= 8'd0;
		sram_data_v[5] <= 8'd0;
		
		temp_u <= 16'd0;
		temp_v <= 16'd0;
		
		R_even <= 8'd0;
		G_even <= 8'd0;
		B_even <= 8'd0;
		R_odd <= 8'd0;
		G_odd <= 8'd0;
		B_odd <= 8'd0;
		
		Y_calc_even <= 64'd0;
		Y_calc_odd <= 64'd0;
		Y_even <= 8'd0;
		Y_odd <= 8'd0;
		
		Ueven_prime <= 32'd0;
		Uodd_prime <= 32'd0;
		Veven_prime <= 32'd0;
		Vodd_prime <= 32'd0;

		yextend_even <= 32'd0;
		yextend_odd <= 32'd0;
	end 
	else begin
		case (state)
		S_m1_IDLE: begin
      //Read enable
			we_n <= 1'b1; 

			//milestone 1 start condition
			if (start == 1'b1) begin
			  done <= 1'b0;
			  state <= S_LEAD_IN_2;		
			end	
		end

		S_LEAD_IN_2: begin
			// read U0 U1
			//SRAM address
			SRAM_address <= counter + U_offset;
			
			//increament Y_counter
			Y_counter <= Y_counter + 18'd1;
			
			//state change
			state <= S_LEAD_IN_3;			
		end
		S_LEAD_IN_3: begin
			// read V0 V1
			//SRAM address
			SRAM_address <= counter + V_offset;
			
			//state change 
			state <= S_LEAD_IN_4;
		end
		S_LEAD_IN_4: begin
			//Y register assignment
			Y_even <= SRAM_read_data [15:8]; 
			Y_odd <= SRAM_read_data [7:0]; 
			
			//counter increment
			counter <= counter + 18'd1;
			
			//state change
			state <= S_LEAD_IN_5;
		end
		S_LEAD_IN_5: begin
		  //SRAM address
		  SRAM_address <= U_offset + counter;
		  
		  //U shift register
		  sram_data_u[0] <= SRAM_read_data[15:8];
		  
		  //Register assignment
			temp_u <= SRAM_read_data;

      //state change
			state <= S_LEAD_IN_6;
		end
		S_LEAD_IN_6: begin
		  //SRAM address
			SRAM_address <= V_offset + counter;
			
			//U shift register
			sram_data_u[1] <= sram_data_u[0];
			
			//V shift register
			sram_data_v[0] <= SRAM_read_data[15:8];
			
			//register assignment
			temp_v <= SRAM_read_data;

      //state change
			state <= S_LEAD_IN_7;
		end
		S_LEAD_IN_7: begin
			
			//U shift register
			sram_data_u[2] <= sram_data_u[1];
			
			//V shifter register
			sram_data_v[1] <= sram_data_v[0];
			
			//state change	
			state <= S_LEAD_IN_8;
		end
		S_LEAD_IN_8: begin
		  
		  //U shift register
		  sram_data_u[3] <= sram_data_u[2];
			sram_data_u[0] <= temp_u[7:0];
			
			//V shift register 
			sram_data_v[2] <= sram_data_v[1];
			
			//register assignment
			temp_u <= SRAM_read_data;
			
			//Y extention
			yextend_even <= {24'b0,Y_even}; //32-bit
			yextend_odd <= {24'b0,Y_odd}; //32-bit
			
			//counter increment
			counter <= counter + 18'd1; //2
      
      //counter that checks which values need to be multiplied in the next state
      calc <= 8'd0;
      
      //state change
			state <= S_LEAD_IN_9;
		end
		S_LEAD_IN_9: begin
    
		  //U shift register
		  sram_data_u[4] <= sram_data_u[3];
			sram_data_u[3] <= sram_data_u[2];
			sram_data_u[2] <= sram_data_u[1];
			sram_data_u[1] <= sram_data_u[0];
			sram_data_u[0] <= temp_u[15:8];
			
			//V shift register
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= temp_v[7:0];
			
			//register assignment
			temp_v <= SRAM_read_data;
    
      //Y calculation
			Y_calc_even <= $signed(m1_res); //64-bit
 			Y_calc_odd <= $signed(m2_res); //64-bit
      
      //state change
			state <= S_LEAD_IN_10;
		end
		S_LEAD_IN_10: begin
		  //SRAM address
			SRAM_address <= U_offset + counter;
			
			//U shift register 
			sram_data_u[5] <= sram_data_u[4];
			sram_data_u[4] <= sram_data_u[3];
			sram_data_u[3] <= sram_data_u[2];
			sram_data_u[2] <= sram_data_u[1];
			sram_data_u[1] <= sram_data_u[0];
			sram_data_u[0] <= temp_u[7:0];
      
      //V shift register			
			sram_data_v[4] <= sram_data_v[3];
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= SRAM_read_data[15:8];
			
			//counter that checks which values need to be multiplied in the next state
      calc <= 8'd1;			
      
			//state change
			state <= S_LEAD_IN_11;
		end
		S_LEAD_IN_11: begin		
      //SRAM address
			SRAM_address <= V_offset + counter;
			
		  //V shift register
		  sram_data_v[5] <= sram_data_v[4];
			sram_data_v[4] <= sram_data_v[3];
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= temp_v[7:0];

      //U calculations
			Ueven_prime <= {24'b0,sram_data_u[3]}; //32
			Uodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) +64'sd128) >> 8; //64-bit			///vreduce <= Vodd_prime[31:0] >> 8; //32-bit
      
      //counter that checks which values need to be multiplied in the next state
      calc <= 8'd2;	
      		
			//state change
			state <= S_LEAD_IN_12;
		end
		S_LEAD_IN_12: begin		
		  //SRAM address
			SRAM_address <= Y_counter;
		  
		  //V calculations
			Veven_prime <= {24'b0,sram_data_v[3]}; //32-bit
			Vodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit

      //Y counter increment
			counter <= counter + 18'd1; //3
			
			//counter that checks which values need to be multiplied in the next state
		  calc <= 8'd3;	
		  
			//state change
			state <= S_LEAD_IN_13;
		end
		S_LEAD_IN_13: begin	
		  //register assignment	
			temp_u <= SRAM_read_data;

      //calculation for G_even
			G_calc <= ($signed(Y_calc_even) + $signed(m1_res) + $signed(m2_res)); //64-bit
      
      //condition that checks if B even is greater then 256 or less then 0
      if($signed(Y_calc_even) + $signed(m3_res) > 32'sd16777216) begin
        B_even <= 16'hffff;
      end
      else if($signed(Y_calc_even) + $signed(m3_res) < 32'sd0) begin
        B_even <= 16'h0000;
      end
      else begin
			 //B even calculations
			 B_even <= ($signed(Y_calc_even) + $signed(m3_res)) >> 16; //64-bit
      end
      
      //Y counter increment
			Y_counter <= Y_counter + 18'd1;
			
			//counter that checks which values need to be multiplied in the next state
      calc <= 8'd4;
      
      //state change
			state <= S_LEAD_IN_14;
		end
		S_LEAD_IN_14: begin  
		  //register assignment
		  temp_v <= SRAM_read_data;
			
			//G reduce to 32-bits
			G_reduce <= G_calc[31:0];
			
			//condition that checks if R even is greater then 256 or less then 0
			if($signed(Y_calc_even) + $signed(m1_res) > 32'sd16777216) begin
			 R_even <= 16'hffff;
			end
			else if($signed(Y_calc_even) + $signed(m1_res) < 32'sd0) begin
			 R_even <= 16'h0000;
			end
			else begin
			 //R even calculation
			 R_even <= ($signed(Y_calc_even) + $signed(m1_res)) >> 16; //64-bit
      end
      
		  //condition that checks if R odd is greater then 256 or less then 0
		  if($signed(Y_calc_odd) + $signed(m2_res) > 32'sd16777216) begin
		    R_odd <= 16'hffff;
		  end
		  else if($signed(Y_calc_odd) + $signed(m2_res) < 32'sd0) begin
		    R_odd <= 16'h0000;
		  end
		  else begin 
		    R_odd <= ($signed(Y_calc_odd) + $signed(m2_res)) >> 16;
		  end
		  
		  //counter that checks which values need to be multiplied in the next state
			calc <= 8'd5;
			
			//state change
			state <= S_TRANSITION_1;
		end

		S_TRANSITION_1: begin		//CLOCK CYCLE 15
			//updating U shift register
		  sram_data_u[5] <= sram_data_u[4];
			sram_data_u[4] <= sram_data_u[3];
			sram_data_u[3] <= sram_data_u[2];
			sram_data_u[2] <= sram_data_u[1];
			sram_data_u[1] <= sram_data_u[0];
			sram_data_u[0] <= temp_u[15:8];
			
			//updating V shift register
			sram_data_v[5] <= sram_data_v[4];
			sram_data_v[4] <= sram_data_v[3];
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= temp_v[15:8];
			
			//Y value assignment
			Y_even <= SRAM_read_data[15:8];
			Y_odd <= SRAM_read_data[7:0];
		
		  //condition that checks if G even is greater then 256 or less then 0
		  if($signed(G_reduce) > 32'sd16777216) begin
		    G_even <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_even <= 16'h0000;
		  end
		  else begin
		    //shifts G even
		    G_even <= G_reduce >> 16;
      end
			
			//calculation for G odd
			G_calc <= ($signed(Y_calc_odd) + $signed(m1_res) + $signed(m2_res)); //64-bit

			//condition that checks if B odd is greater then 256 or less then 0
      if($signed(Y_calc_odd) + $signed(m3_res) > 32'sd16777216) begin
        B_odd <= 16'hffff;
      end
      else if($signed(Y_calc_odd) + $signed(m3_res) < 32'sd0) begin
        B_odd <= 16'h0000;
      end
      else begin
			  B_odd <= ($signed(Y_calc_odd) + $signed(m3_res)) >> 16; //64-bit
      end
      
      //counter that checks which values need to be multiplied in the next state
			calc <= 8'd6;
			
			//state change
			state <= S_TRANSITION_2;
		end
		S_TRANSITION_2: begin		//CLOCK CYCLE 16
		  //RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; //2
			
			//writing SRAM address
			SRAM_address <= RGB_offset + RGB_counter;
			
			//Writing RGB values
			SRAM_write_data <= {R_even[7:0], G_even[7:0]};
			
		  //write enabled
			we_n <= 1'b0;
			
			//G reduce
			G_reduce <= G_calc[31:0];

			//U calculations
			Ueven_prime <= {24'b0,sram_data_u[3]}; //32
			Uodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit

			//state change
			state <= S_TRANSITION_2_5;
		end
		
		S_TRANSITION_2_5: begin
		  //Writing RGB values
			SRAM_write_data <= {B_even[7:0], R_odd[7:0]};
			
			//SRAM address 
			SRAM_address <= RGB_offset + RGB_counter;
			
			//condition that checks if G odd even is greater then 256 or less then 0
		  if($signed(G_reduce) > 32'sd16777216) begin
		    //G reduce when it exceeds 256 
		    G_odd <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_odd <= 16'h0000;
		  end
		  else begin
		    //G reduce	
		    G_odd <= G_reduce >> 16;
      end
			
      //RGB counter increment
		  RGB_counter <= RGB_counter + 16'd1; //1
		  
		  //counter that checks which values need to be multiplied in the next state
			calc <= 8'd7;
			
		  //state change
			state <= S_TRANSITION_3;
		end

		S_TRANSITION_3: begin		//CLOCK CYCLE 17
		  //writing RBG values
			SRAM_write_data <= {G_odd[7:0], B_odd[7:0]};

			//V calculation
			Veven_prime <= {24'b0,sram_data_v[3]}; //32
			Vodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit

      //Y extensions
			yextend_even <= {24'b0,Y_even}; //32-bit
			yextend_odd <= {24'b0,Y_odd}; //32-bit
  
      //SRAM address 
			SRAM_address <= RGB_offset + RGB_counter;
			
			//RGB counter increment
		  RGB_counter <= RGB_counter + 16'd1; //1

      //state change
			state <= S_TRANSITION_3_5;
		end
		S_TRANSITION_3_5: begin		//CLOCK CYCLE 18
		  //SRAM address
			SRAM_address <= Y_counter;
			
		   //read enable
      we_n <= 1'b1;
      
      //counter that checks which values need to be multiplied in the next state
      calc <= 8'd8;
      
      //state change
      state <= S_TRANSITION_4;
		 end
	
		S_TRANSITION_4: begin		//CLOCK CYCLE 18
			//SRAM address
			SRAM_address <= U_offset + counter;
			
			//U shift register
			sram_data_u[5] <= sram_data_u[4];
			sram_data_u[4] <= sram_data_u[3];
			sram_data_u[3] <= sram_data_u[2];
			sram_data_u[2] <= sram_data_u[1];
			sram_data_u[1] <= sram_data_u[0];
			sram_data_u[0] <= temp_u[7:0];
			
			//V shift register
			sram_data_v[5] <= sram_data_v[4];
			sram_data_v[4] <= sram_data_v[3];
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= temp_v[7:0];
			            
			//Y calulations
			Y_calc_even <= $signed(m1_res); //64-bit
 			Y_calc_odd <= $signed(m2_res); //64-bit
 			
 			//counter that checks which values need to be multiplied in the next state
 			calc <= 8'd9;
 			
			//state change
			state <= S_TRANSITION_5;
		end
		S_TRANSITION_5: begin		//CLOCK CYCLE 19
		  //SRAM address
			SRAM_address <= V_offset + counter;

      //calculation for G even
			G_calc <= ($signed(Y_calc_even) + $signed(m1_res) + $signed(m2_res)); //64-bit
			
			//condition that checks if B odd is greater then 256 or less then 0
      if($signed(Y_calc_even) + $signed(m3_res) > 32'sd16777216) begin
        B_even <= 16'hffff;
      end
      else if($signed(Y_calc_even) + $signed(m3_res) < 32'sd0) begin
        B_even <= 16'h0000;
      end
      else begin  
			  //B even calculations
			  B_even <= ($signed(Y_calc_even) + $signed(m3_res)) >> 16; //64-bit
      end
      
      //Y counter increment
			Y_counter <= Y_counter + 16'd1;
            
      //counter that checks which values need to be multiplied in the next state      
      calc <= 8'd10;
      
      //state change
			state <= S_TRANSITION_6;
		end
		S_TRANSITION_6: begin		//CLOCK CYCLE 20
			//Y assignment
			Y_even <= SRAM_read_data[15:8];
			Y_odd <= SRAM_read_data[7:0];
			
			//G reduce
			G_reduce <= G_calc[31:0];
			
			//condition that checks if R even is greater then 256 or less then 0
		  if($signed(Y_calc_even) + $signed(m1_res) > 32'sd16777216) begin
		    	R_even <= 16'hffff;
		  end
		  else if($signed(Y_calc_even) + $signed(m1_res) < 32'sd0) begin
		     R_even <= 16'h0000;
		  end
		  else begin 
		  		 R_even <= (Y_calc_even + m1_res) >> 16; //64-bit
		  end
		  
		  //condition that checks if R odd is greater then 256 or less then 0
		  if($signed(Y_calc_odd) + $signed(m2_res) > 32'sd16777216) begin
		    R_odd <= 16'hffff;
		  end
		  else if($signed(Y_calc_odd) + $signed(m2_res) < 32'sd0) begin
		    R_odd <= 16'h0000;
		  end
		  else begin 
		    R_odd <= (Y_calc_odd + m2_res) >> 16;
		  end
		  
		  //counter that checks which values need to be multiplied in the next state
			calc <= 8'd11;
			
			//state change
			state <= S_TRANSITION_7;
		end
		S_TRANSITION_7: begin		//CLOCK CYCLE 21
			//register assignment
			temp_u <= SRAM_read_data;
      			
 			//condition that checks if G even is greater then 256 or less then 0
 			if($signed(G_reduce) > 32'sd16777216) begin
		    //G reduce when it exceeds 256 
		    G_even <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_even <= 16'h0000;
		  end
		  else begin
		    //G reduce	
		    G_even <= G_reduce >> 16;
      end
      
			G_calc <= ($signed(Y_calc_odd) + $signed(m1_res) + $signed(m2_res)); //64-bit
			
			//condition that checks if B odd is greater then 256 or less then 0
      if($signed(Y_calc_odd) + $signed(m3_res) > 32'sd16777216) begin
        B_odd <= 16'hffff;
      end
      else if($signed(Y_calc_odd) + $signed(m3_res) < 32'sd0) begin
        B_odd <= 16'h0000;
      end
      else begin
			  //B even calculations
			  B_odd <= ($signed(Y_calc_odd) + $signed(m3_res)) >> 16; //64-bit
      end			

			//counter increment
			counter <= counter + 16'd1;
			
			//transition to common state flag
			trans <= 1'b1;
			
			//inital read of U and V flag
			read_uv <= 1'b1;
			
			//state change
			state <= S_COMMONE_CASE_1;
		end

		S_COMMONE_CASE_1: begin		//CLOCK CYCLE 22
      //writing SRAM address		
  			SRAM_address <= RGB_offset + RGB_counter;
  			
  			//write RGB values
			SRAM_write_data <= {R_even[7:0], G_even[7:0]};
		
		  //checks if it's a common to common or a transition to common state situation
			if(read_uv == 1'b1 && trans == 1'b0) begin
			  temp_u <= SRAM_read_data;
			end
			else if(trans == 1'b1) begin
			  trans<= 1'b0;
			  temp_v <= SRAM_read_data;
			end

      //RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; //4
			
			//G reduce
			G_reduce <= G_calc[31:0];
			
			//write enable	
			we_n <= 1'b0;
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd12;
			
			//state change
			state <= S_COMMONE_CASE_2;
		end
		S_COMMONE_CASE_2: begin		//CLOCK CYCLE 23
		  //temp_v <= SRAM_read_data;
		  //checks if this common state needs to read a new U or V value
		  if(read_uv == 1'b1) begin
			  temp_v <= SRAM_read_data;
				read_uv <= ~read_uv;
			end
			else if(read_uv == 1'b0)
				read_uv <= ~read_uv;
			
			//U odd calculation
			Ueven_prime <= {24'b0,sram_data_u[3]}; //32
			Uodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit
			
			//write RGB values
			SRAM_write_data <= {B_even[7:0], R_odd[7:0]};
			
			//write SRAM address
			SRAM_address <= RGB_offset + RGB_counter;
			
			//RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; //5
		  
		  //condition that checks if G odd is greater then 256 or less then 0	
		  if($signed(G_reduce) > 32'sd16777216) begin
		    //G reduce when it exceeds 256 
		    G_odd <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_odd <= 16'h0000;
		  end
		  else begin
		    //G reduce	
		    G_odd <= G_reduce >> 16;
      end
      
      //counter that checks which values need to be multiplied in the next state
      calc <= 8'd13;
      
		  //state change
			state <= S_COMMONE_CASE_3;
		end
		S_COMMONE_CASE_3: begin		//CLOCK CYCLE 24
		  //write RGB values
			SRAM_write_data <= {G_odd[7:0], B_odd[7:0]};
			
			//write SRAM address
			SRAM_address <= RGB_offset + RGB_counter;
			
			//RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; //6
							
			//update shift register if a new U or V is gotten
			if(read_uv == 1'b0) begin 
			 sram_data_u[5] <= sram_data_u[4];
			 sram_data_u[4] <= sram_data_u[3];
			 sram_data_u[3] <= sram_data_u[2];
			 sram_data_u[2] <= sram_data_u[1];
			 sram_data_u[1] <= sram_data_u[0];
			 sram_data_u[0] <= temp_u[15:8];
			
			 sram_data_v[5] <= sram_data_v[4];
			 sram_data_v[4] <= sram_data_v[3];
			 sram_data_v[3] <= sram_data_v[2];
			 sram_data_v[2] <= sram_data_v[1];
			 sram_data_v[1] <= sram_data_v[0];
			 sram_data_v[0] <= temp_v[15:8];
			end
			else if(read_uv == 1'b1) begin
			 sram_data_u[5] <= sram_data_u[4];
			 sram_data_u[4] <= sram_data_u[3];
			 sram_data_u[3] <= sram_data_u[2];
			 sram_data_u[2] <= sram_data_u[1];
			 sram_data_u[1] <= sram_data_u[0];
			 sram_data_u[0] <= temp_u[7:0];
			
			 sram_data_v[5] <= sram_data_v[4];
			 sram_data_v[4] <= sram_data_v[3];
			 sram_data_v[3] <= sram_data_v[2];
			 sram_data_v[2] <= sram_data_v[1];
			 sram_data_v[1] <= sram_data_v[0];
			 sram_data_v[0] <= temp_v[7:0];
			end
			
			//Y value extension
			yextend_even <= {24'b0,Y_even}; //32-bit
			yextend_odd <= {24'b0,Y_odd}; //32-bit
			
			//V odd calculation
			Veven_prime <= {24'b0,sram_data_v[3]}; //32
			Vodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit

      //RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; //6
			
			//counter that checks which values need to be multiplied in the next state
      calc <= 8'd14;
      
      //state change
			state <= S_COMMONE_CASE_4;
		end
		S_COMMONE_CASE_4: begin		//CLOCK CYCLE 25
			//SRAM address
			SRAM_address <= Y_counter;
			
			//Y value calculation
			Y_calc_even <= $signed(m1_res); //64-bit
 			Y_calc_odd <= $signed(m2_res); //64-bit
 			
			//read enable
			we_n <= 1'b1;
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd15;
			
	    //state change
			state <= S_COMMONE_CASE_5;
		end
		S_COMMONE_CASE_5: begin		//CLOCK CYCLE 26
      //calculation for G even
			G_calc <= ($signed(Y_calc_even) + $signed(m1_res) + $signed(m2_res)); //64-bit
			
			//condition that checks if B even is greater then 256 or less then 0	
		  if($signed(Y_calc_even) + $signed(m3_res) > 32'sd16777216) begin
		    	B_even <= 16'hffff;
		  end
		  else if($signed(Y_calc_even) + $signed(m3_res) < 32'sd0) begin
		     B_even <= 16'h0000;
		  end
		  else begin 
		  		 B_even <= ($signed(Y_calc_even) + $signed(m3_res)) >> 16; //64-bit
		  end
			
			//checks if the common state should end and go into lead out for that line
			if(read_uv == 1'b1 && (Y_counter + 16'd4)%16'd160 != 0) begin
			 SRAM_address <= U_offset + counter;
			end
			
		  //Y counter increment
			Y_counter <= Y_counter + 16'd1;
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd16;
			
			//state change
			state <= S_COMMONE_CASE_6;
		end
		S_COMMONE_CASE_6: begin		//CLOCK CYCLE 27	
		  //condition that checks if R even is greater then 256 or less then 0	
		  if($signed(Y_calc_even) + $signed(m1_res) > 32'sd16777216) begin
		    	R_even <= 16'hffff;
		  end
		  else if($signed(Y_calc_even) + $signed(m1_res) < 32'sd0) begin
		     R_even <= 16'h0000;
		  end
		  else begin 
		  		 R_even <= ($signed(Y_calc_even) + $signed(m1_res)) >> 16; //64-bit
		  end
		  
		  //condition that checks if R odd is greater then 256 or less then 0	
		  if($signed(Y_calc_odd) + $signed(m2_res) > 32'sd16777216) begin
		    R_odd <= 16'hffff;
		  end
		  else if($signed(Y_calc_odd) + $signed(m2_res) < 32'sd0) begin
		    R_odd <= 16'h0000;
		  end
		  else begin 
		    R_odd <= ($signed(Y_calc_odd) + $signed(m2_res)) >> 16;
		  end
			
			//G reduce
			G_reduce <= G_calc[31:0];
			
		  //checks if the common state needs to read a new U or V value
		  if(read_uv == 1'b1 && (Y_counter + 16'd3)%16'd160 != 0) begin
		    SRAM_address <= V_offset + counter;
		  end	
		  
			//increment counter if a U or V is read in this common state
			if(read_uv == 1'b1 && (Y_counter + 16'd3)%16'd160 != 0) begin
			 counter <= counter + 16'd1;
			end
			
		  //counter that checks which values need to be multiplied in the next state
      calc <= 8'd17;
      
			//state change
			state <= S_COMMONE_CASE_7;
		end
		S_COMMONE_CASE_7: begin		//CLOCK CYCLE 28
      //Y register assignment
			Y_even <= SRAM_read_data[15:8];
		  Y_odd <= SRAM_read_data[7:0];
		  
		  //condition that checks if G even is greater then 256 or less then 0
		  if($signed(G_reduce) > 32'sd16777216) begin
		    G_even <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_even <= 16'h0000;  
		  end
		  else begin
		    G_even <= G_reduce >> 16;
		  end 

      //condition that checks if G odd is greater then 256 or less then 0	
			G_calc <= ($signed(Y_calc_odd) + $signed(m1_res) + $signed(m2_res)); //64-bit
			
			//condition that checks if B odd is greater then 256 or less then 0	
      if($signed(Y_calc_odd) + $signed(m3_res) > 32'sd16777216) begin
        B_odd <= 16'hffff;
      end
      else if($signed(Y_calc_odd) + $signed(m3_res) < 32'sd0) begin
        B_odd <= 16'h0000;
      end
      else begin
			  //B even calculations
			  B_odd <= ($signed(Y_calc_odd) + $signed(m3_res)) >> 16; //64-bit
      end		
			
			//check if there are more common states needed if not goes to lead out
			if((Y_counter + 16'd3) % 16'd160 == 16'd0)
				state <= S_LEAD_OUT_1;
			else
			
			//state change  
			state <= S_COMMONE_CASE_1;
		end
		S_LEAD_OUT_1: begin  //50
		  //write RGB address			
			SRAM_address <= RGB_offset + RGB_counter;

			//write enable
			we_n <= 1'b0;
			
			//write RGB value
			SRAM_write_data <= {R_even[7:0], G_even[7:0]};
      
      //G reduce 
      G_reduce <= G_calc[31:0];
      
      //RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; 
		
			//lead_out_counter 
			lead_out_counter <= lead_out_counter + 4'd1;
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd18;
			
			//state change
			state <= S_LEAD_OUT_2;
		end
		S_LEAD_OUT_2: begin		
		  //write RGB value
			SRAM_write_data <= {B_even[7:0], R_odd[7:0]};
			
			//write RGB address
			SRAM_address <= RGB_offset + RGB_counter;					

      //U value calculation
			Ueven_prime <= {24'b0,sram_data_u[3]}; //32
			Uodd_prime <= ($signed(m1_res) - $signed(m2_res) + $signed(m3_res) + 64'sd128) >> 8; //64-bit

   			//Y value extension
			yextend_even <= {24'b0,Y_even}; //32-bit
			yextend_odd <= {24'b0,Y_odd}; //32-bit
			
			//condition that checks if G odd is greater then 256 or less then 0	
			if($signed(G_reduce) > 32'sd16777216) begin
		    G_odd <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_odd <= 16'h0000;
		  end
		  else begin
		    G_odd <= G_reduce >> 16;
		  end 
      
			//RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; 
			
			//counter that checks which values need to be multiplied in the next state	
			calc <= 8'd19;
			
			//state change 
			state <= S_LEAD_OUT_3;
		end
		S_LEAD_OUT_3: begin		//52
	   	//write RGB value
			SRAM_write_data <= {G_odd[7:0], B_odd[7:0]};
			
			//write RGB address
			SRAM_address <= RGB_offset + RGB_counter;					

		  //V odd calculation
			Veven_prime <= {24'b0,sram_data_v[3]}; //32
			Vodd_prime <= $signed(m1_res - m2_res + m3_res + 64'd128) >> 8; //64-bit
			
   			//RGB counter increment
			RGB_counter <= RGB_counter + 16'd1; 
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd20;
			
			//state change
			state <= S_LEAD_OUT_4;
		end
		S_LEAD_OUT_4: begin		//CLOCK CYCLE 53
		  //checks if lead needs to go to the Y address
      if(lead_out_counter != 4'd4) begin
        //SRAM address
			 	SRAM_address <= Y_counter;
			end
      
      //repeated update of the register for the same value in lead out
			sram_data_u[5] <= sram_data_u[4];
			sram_data_u[4] <= sram_data_u[3];
			sram_data_u[3] <= sram_data_u[2];
			sram_data_u[2] <= sram_data_u[1];
			sram_data_u[1] <= sram_data_u[0];
			sram_data_u[0] <= temp_u[7:0];
			
		  sram_data_v[5] <= sram_data_v[4];
			sram_data_v[4] <= sram_data_v[3];
			sram_data_v[3] <= sram_data_v[2];
			sram_data_v[2] <= sram_data_v[1];
			sram_data_v[1] <= sram_data_v[0];
			sram_data_v[0] <= temp_v[7:0];
			
      //Y value calculation
			Y_calc_even <= $signed(m1_res); //64-bit
 			Y_calc_odd <= $signed(m2_res); //64-bit

      //read enable
			we_n <= 1'b1;
			
			//counter that checks which values need to be multiplied in the next state	
		  calc <= 8'd21;
		  
			//state change
			state <= S_LEAD_OUT_5;
		end
		
		S_LEAD_OUT_5: begin		//CLOCK CYCLE 54
      //calculation for G even
			G_calc <= ($signed(Y_calc_even) + $signed(m1_res) + $signed(m2_res)); //64-bit

			//condition that checks if B even is greater then 256 or less then 0	
		  if($signed(Y_calc_even) + $signed(m3_res) > 32'sd16777216) begin
		    	B_even <= 16'hffff;
		  end
		  else if($signed(Y_calc_even) + $signed(m3_res) < 32'sd0) begin
		     B_even <= 16'h0000;
		  end
		  else begin 
		  		 B_even <= ($signed(Y_calc_even) + $signed(m3_res)) >> 16; //64-bit
		  end
		  
		  //checks if y address needs to be incremented
		  if(lead_out_counter != 4'd4) begin
        //Y counter increment
			  Y_counter <= Y_counter + 16'd1;
			end
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd22;
			
			//state change
			state <= S_LEAD_OUT_6;
		end
		S_LEAD_OUT_6: begin		//CLOCK CYCLE 55
		
			//condition that checks if R even is greater then 256 or less then 0	
		  if($signed(Y_calc_even) + $signed(m1_res) > 32'sd16777216) begin
		    	R_even <= 16'hffff;
		  end
		  else if($signed(Y_calc_even) + $signed(m1_res) < 32'sd0) begin
		     R_even <= 16'h0000;
		  end
		  else begin 
		  		 R_even <= ($signed(Y_calc_even) + $signed(m1_res)) >> 16; //64-bit
		  end
		  
		  //condition that checks if R odd is greater then 256 or less then 0	
		  if($signed(Y_calc_odd) + $signed(m2_res) > 32'sd16777216) begin
		    R_odd <= 16'hffff;
		  end
		  else if($signed(Y_calc_odd) + $signed(m2_res) < 32'sd0) begin
		    R_odd <= 16'h0000;
		  end
		  else begin 
		    R_odd <= ($signed(Y_calc_odd) + $signed(m2_res)) >> 16;
		  end

      //reducing the G calculated to a 32-bit answer
     	G_reduce <= G_calc[31:0];
			
			//counter that checks which values need to be multiplied in the next state
			calc <= 8'd23;
			
			//state change
			state <= S_LEAD_OUT_7;
		end
		S_LEAD_OUT_7: begin		//CLOCK CYCLE 56
		  //condition that checks if G even is greater then 256 or less then 0	
			if($signed(G_reduce) > 32'sd16777216) begin
		    G_even <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_even <= 16'h0000;
		  end
		  else begin
		    G_even <= G_reduce >> 16;
		  end 
			
			//calculation for G odd
			G_calc <= ($signed(Y_calc_odd) + $signed(m1_res) + $signed(m2_res)); //64-bit

      //condition that checks if B odd is greater then 256 or less then 0	
      if($signed(Y_calc_odd) + $signed(m3_res) > 32'sd16777216) begin
        B_odd <= 16'hffff;
      end
      else if($signed(Y_calc_odd) + $signed(m3_res) < 32'sd0) begin
        B_odd <= 16'h0000;
      end
      else begin
			  //B even calculations
			  B_odd <= ($signed(Y_calc_odd) + $signed(m3_res)) >> 16; //64-bit
      end		

			//Y register assignment
			Y_even <= SRAM_read_data[15:8];
			Y_odd <= SRAM_read_data[7:0];
			
			//checks if lead out is finished which is kept track using the lead_out counter 
			if (lead_out_counter == 4'd4) begin
			  trans <= ~trans;
			  lead_out_counter <= 4'd0;
			  state <= S_FINAL_1;
			end
			else begin
			 state <= S_LEAD_OUT_1;
      end
		end
		
		//prints the final calculation of the lead out
		S_FINAL_1: begin
		  //RGB write address
		  SRAM_address <= RGB_offset + RGB_counter; 
		  
		  //updates the write address for RGB
		  RGB_counter <= RGB_counter + 16'd1;
		  
		  //reduces G to be a 32-bit value
		  G_reduce <= G_calc[31:0];
		  
		  //writes the calculated RGB values
		  SRAM_write_data <= {R_even[7:0], G_even[7:0]};
		  
		  //write enable
		  we_n <= 1'b0;
		  
		  //state change
		  state <= S_FINAL_2;
		end
		S_FINAL_2: begin
		  //RGB write address
		  SRAM_address <= RGB_offset + RGB_counter; 
		  
		  //updates the write address for RGB
		  RGB_counter <= RGB_counter + 16'd1;
		  
		  //condition that checks if G odd is greater then 256 or less then 0	
  		  if($signed(G_reduce) > 32'sd16777216) begin
		    G_odd <= 16'hffff;
		  end
		  else if($signed(G_reduce) < 32'sd0) begin
		    G_odd <= 16'h0000;
		  end
		  else begin
		    G_odd <= G_reduce >> 16;
		  end 
		  
		  //writes the calculated RGB values
		  SRAM_write_data <= {B_even[7:0], R_odd[7:0]};
		  
		  //state change 
		  state <= S_FINAL_3;
		end
		S_FINAL_3: begin
		  //RGB write address
		  SRAM_address <= RGB_offset + RGB_counter; 
		  
		  //updates the write address for RGB
		  RGB_counter <= RGB_counter + 16'd1;
		  
		  //writes the calculated RGB values
		  SRAM_write_data <= {G_odd[7:0], B_odd[7:0]};
		  
		  //checks if milestone is done or not to flag the done register
		  if(RGB_counter == 32'd115199) 
		    done <= 1'b1;
		    
		  //state change 
		  state <= S_FINAL_4;
		end
		S_FINAL_4: begin
		  //address for y after lead out 
      SRAM_address <= Y_counter;
      
      //read enable
		  we_n <= 1'b1;
		  
		  //state change
		  state <= S_m1_IDLE;
		end
		default: state <= S_m1_IDLE;
		endcase
	end
end

//combination circuit for multipliers
always_comb begin
   //depending on calc register then it would decide which values should be multiplied
   if(calc == 8'b0)
     m1_state = C_LEAD_IN_9;
   else if(calc == 8'd1)  
     m1_state =  C_LEAD_IN_11;
   else if(calc == 8'd2)
     m1_state= C_LEAD_IN_12;
   else if(calc == 8'd3)
     m1_state = C_LEAD_IN_13;
   else if(calc == 8'd4)
     m1_state = C_LEAD_IN_14;
   else if(calc  == 8'd5)
     m1_state = C_LEAD_IN_15;
   else if(calc == 8'd6)
     m1_state = C_TRANSITION_2;
   else if(calc == 8'd7)
     m1_state = C_TRANSITION_3;
   else if(calc == 8'd8)
     m1_state = C_TRANSITION_4;
   else if(calc == 8'd9)
     m1_state = C_TRANSITION_5;   
   else if(calc == 8'd10)
     m1_state = C_TRANSITION_6;  
   else if(calc == 8'd11)
     m1_state = C_TRANSITION_7;
   else if(calc == 8'd12)
     m1_state = C_COMMON_CASE_2;
   else if(calc == 8'd13)
     m1_state = C_COMMON_CASE_3;
   else if(calc == 8'd14)
     m1_state = C_COMMON_CASE_4;   
   else if(calc == 8'd15)
     m1_state = C_COMMON_CASE_5; 
   else if(calc == 8'd16)
     m1_state = C_COMMON_CASE_6;   
   else if(calc == 8'd17)
     m1_state = C_COMMON_CASE_7;    
   else if(calc == 8'd18)
     m1_state = C_LEAD_OUT_2;   
   else if(calc == 8'd19)
     m1_state = C_LEAD_OUT_3;   
   else if(calc == 8'd20)
     m1_state = C_LEAD_OUT_4; 
   else if(calc == 8'd21)
     m1_state = C_LEAD_OUT_5;     
   else if(calc == 8'd22)
     m1_state = C_LEAD_OUT_6;   
   else if(calc == 8'd23)
     m1_state = C_LEAD_OUT_7;
	else
		m1_state = C_BLANK;
	
	//the different cases
  case(m1_state)
    C_BLANK: begin //default blank case
      m1_op1 = 0;
      m1_op2 = 0;
      m2_op1 = 0;
      m2_op2 = 0;
      m3_op1 = 0;
      m3_op2 = 0;
    end
    C_LEAD_IN_9: begin
      m1_op1 = $signed(yextend_even - y);
      m1_op2 = $signed(a); //76284
      m2_op1 = $signed(yextend_odd - y);
      m2_op2 = $signed(a);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_LEAD_IN_11: begin
      m1_op1 =(sram_data_u[0]+sram_data_u[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_u[1]+sram_data_u[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_u[2]+sram_data_u[3]);
      m3_op2 = 8'd159;
    end
    C_LEAD_IN_12: begin
      m1_op1 =(sram_data_v[0]+sram_data_v[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_v[1]+sram_data_v[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_v[2]+sram_data_v[3]);
      m3_op2 = 8'd159;
    end
    C_LEAD_IN_13: begin
      m1_op1 = $signed(Ueven_prime) - 32'd128;
      m1_op2 = $signed(l);
      m2_op1 = $signed(Veven_prime) - 32'd128;
      m2_op2 = $signed(m);
      m3_op1 = $signed(Ueven_prime) - 32'd128;
      m3_op2 = $signed(s);
    end
    C_LEAD_IN_14: begin
      m1_op1 = $signed(Veven_prime - 32'd128);
      m1_op2 = $signed(c);
      m2_op1 = $signed(Vodd_prime - 32'd128);
      m2_op2 = $signed(c);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_LEAD_IN_15: begin
      m1_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Vodd_prime[31:0]) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m3_op2 = $signed(s);      
    end
    C_TRANSITION_2: begin
      m1_op1 =(sram_data_u[0]+sram_data_u[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_u[1]+sram_data_u[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_u[2]+sram_data_u[3]);
      m3_op2 = 8'd159;
    end
    C_TRANSITION_3: begin
      m1_op1 =(sram_data_v[0]+sram_data_v[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_v[1]+sram_data_v[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_v[2]+sram_data_v[3]);
      m3_op2 = 8'd159;
    end
    C_TRANSITION_4: begin
      m1_op1 = $signed(yextend_even - y);
      m1_op2 = $signed(a);
      m2_op1 = $signed(yextend_odd - y);
      m2_op2 = $signed(a);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_TRANSITION_5: begin
      m1_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Veven_prime) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m3_op2 = $signed(s);      
    end
    C_TRANSITION_6: begin
      m1_op1 = $signed(Veven_prime) - $signed(32'd128);
      m1_op2 = $signed(c);
      m2_op1 = $signed(Vodd_prime[31:0]) - $signed(32'd128);
      m2_op2 = $signed(c);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_TRANSITION_7: begin
      m1_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Vodd_prime[31:0]) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m3_op2 = $signed(s);            
    end
    C_COMMON_CASE_2: begin
      m1_op1 =(sram_data_u[0]+sram_data_u[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_u[1]+sram_data_u[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_u[2]+sram_data_u[3]);
      m3_op2 = 8'd159;
    end
    C_COMMON_CASE_3: begin
      m1_op1 =(sram_data_v[0]+sram_data_v[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_v[1]+sram_data_v[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_v[2]+sram_data_v[3]);
      m3_op2 = 8'd159;
    end
    C_COMMON_CASE_4: begin
      m1_op1 = $signed(yextend_even - y);
      m1_op2 = $signed(a);
      m2_op1 = $signed(yextend_odd - y);
      m2_op2 = $signed(a);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_COMMON_CASE_5: begin
      m1_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Veven_prime) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m3_op2 = $signed(s);  
    end
    C_COMMON_CASE_6: begin
      m1_op1 = $signed(Veven_prime - 32'd128);
      m1_op2 = $signed(c);
      m2_op1 = $signed(Vodd_prime[31:0] - 32'd128);
      m2_op2 = $signed(c);
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_COMMON_CASE_7: begin
      m1_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Vodd_prime[31:0]) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Uodd_prime[31:0]) - $signed(32'd128);
      m3_op2 = $signed(s);      
    end
    C_LEAD_OUT_2:  begin
      m1_op1 =(sram_data_u[0]+sram_data_u[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_u[1]+sram_data_u[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_u[2]+sram_data_u[3]);
      m3_op2 = 8'd159;     
    end
    C_LEAD_OUT_3: begin
      m1_op1 =(sram_data_v[0]+sram_data_v[5]);
      m1_op2 = 8'd21;
      m2_op1 =(sram_data_v[1]+sram_data_v[4]);
      m2_op2 = 8'd52;
      m3_op1 =(sram_data_v[2]+sram_data_v[3]);
      m3_op2 = 8'd159;
    end
    C_LEAD_OUT_4: begin
      m1_op1 = $signed(yextend_even - y);
      m1_op2 = a;
      m2_op1 = $signed(yextend_odd - y);
      m2_op2 = a;  
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;		
    end
    C_LEAD_OUT_5: begin
      m1_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Veven_prime) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Ueven_prime) - $signed(32'd128);
      m3_op2 = $signed(s);        
    end
    C_LEAD_OUT_6: begin
      m1_op1 = $signed(Veven_prime[31:0]) - $signed(32'd128);
      m1_op2 = c;
      m2_op1 = $signed(Vodd_prime[31:0]) - $signed(32'd128);
      m2_op2 = c;   
		m3_op1 = 32'd0;
      m3_op2 = 32'd0;
    end
    C_LEAD_OUT_7: begin
      m1_op1 = $signed(Uodd_prime) - $signed(32'd128);
      m1_op2 = $signed(l);
      m2_op1 = $signed(Vodd_prime) - $signed(32'd128);
      m2_op2 = $signed(m);
      m3_op1 = $signed(Uodd_prime) - $signed(32'd128);
      m3_op2 = $signed(s);       
    end
    default: m1_state = C_BLANK;
  		endcase
end
endmodule