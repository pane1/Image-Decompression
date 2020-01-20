`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone2(
 input CLOCK_50,
 input logic start,
 input logic[15:0] SRAM_read_data,
 input logic Resetn,
 
 output logic[15:0] SRAM_write_data,
 output logic done,
 output logic[17:0] SRAM_address,
 output logic we_n
  
);

//m2_s_state
m2_state_type m2_s_state;
m2_state_type m2_C_state;

//registers
logic[31:0] m1_op1, m1_op2, m2_op1, m2_op2, m1_res, m2_res;
logic[6:0] address1, address2, address3, address4;
logic[31:0] input_1, input_2, input_3, input_4;
logic[31:0] output_1, output_2, output_3, output_4;

logic[31:0] temp_t0, temp_t1, temp_t2, temp_t3, temp_t4, temp_t5, temp_t6, temp_t7;
logic[31:0] temp_s0, temp_s1, temp_s2, temp_s3, temp_s4, temp_s5, temp_s6, temp_s7;
logic[31:0] temp_s_even, temp_s_odd;
logic[31:0] temp_t_even, temp_t_odd;

logic we_1,we_2,we_3,we_4;

//assignment of multipliers 
assign m1_res = m1_op1 * m1_op2;
assign m2_res = m2_op1 * m2_op2;

// RAMs for storing Char ROM code
dual_port_RAM0 unit1 (
	.address_a (address1),
	.address_b (address2),
	.clock (CLOCK_50),
	.data_a (input_1),
	.data_b (input_2),
	.wren_a (we_1),
	.wren_b (we_2),
	.q_a (output_1),
	.q_b (output_2)
	);

dual_port_RAM1 unit2 (
	.address_a (address3),
	.address_b (address4),
	.clock (CLOCK_50),
	.data_a (input_3),
	.data_b (input_4),
	.wren_a (we_3),
	.wren_b (we_4),
	.q_a (output_3),
	.q_b (output_4)
	);
	
//flags
logic lead_out;
logic transpose;

//counters
logic[17:0] fetch_counter;
logic[6:0] counter;
logic[7:0] T_counter;
logic[7:0] t_calc_counter;
logic[7:0] s_calc_counter;
logic[17:0] write_counter;
logic[17:0] read_counter;
logic[7:0] calc;
logic[15:0] base_even;
logic[15:0] base_odd;

//assignments of offsets
parameter U_offset = 38400,
  V_offset = 57600,
  in_offset = 76800;

always_ff @ (posedge  CLOCK_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		m2_s_state <= S_m2_IDLE;
		
		we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		address1 <=7'd0;
		address2 <=7'd0;
		address3 <=7'd0;
		address4 <=7'd0;

		fetch_counter <=18'd0;
		counter <=7'd0;
		T_counter <=8'd0;
		t_calc_counter <=8'd0;
		s_calc_counter <=8'd0;
		write_counter <= 18'd0;
		read_counter <= 18'd0;
		calc <= 8'd0;
		
		lead_out <= 1'b0;
		transpose <= 1'b0;
		
		we_1 <= 1'b0;
		we_2 <= 1'b0;
		we_3 <= 1'b0;
		we_4 <= 1'b0;

		base_even <= 16'd0;
		base_odd <= 16'd1;
		
		input_1 <= 32'd0;
		input_2 <= 32'd0;
		input_3 <= 32'd0;
		input_4 <= 32'd0;
		temp_t0<=32'd0;
		temp_t1<=32'd0;
		temp_t2<=32'd0;
		temp_t3<=32'd0;
		temp_t4<=32'd0;
		temp_t5<=32'd0;
		temp_t6<=32'd0;
		temp_t7<=32'd0;
		temp_s0<=32'd0;
		temp_s1<=32'd0;
		temp_s2<=32'd0;
		temp_s3<=32'd0;
		temp_s4<=32'd0;
		temp_s5<=32'd0;
		temp_s6<=32'd0;
		temp_s7<=32'd0; 
		
		input_1<= 32'd0;
		input_2<= 32'd0;
		input_3<= 32'd0;
		input_4<= 32'd0;
		
		temp_s_even<= 32'd0;
		temp_s_odd<= 32'd0;
		temp_t_even<= 32'd0;
		temp_t_odd<= 32'd0;  
	end
	else begin
		case(m2_s_state)
		S_m2_IDLE: begin
			we_n <= 1'b1;
		  
			//milestone 2 start condotion
			if (start == 1'b1) begin
				//initialize flags and counters
				done <= 1'b0;
				SRAM_address <= in_offset + fetch_counter; 
				fetch_counter <= fetch_counter + 8'd1;
				read_counter <= read_counter + 18'd1;
				m2_s_state <= S_LEAN_IN_FETCH_1;
				transpose <= 1'b1;
			end
		end 
    
		S_LEAN_IN_FETCH_1: begin
			//start fetching S'[0]
			SRAM_address <= in_offset + fetch_counter; 
			fetch_counter <= fetch_counter + 8'd1;
			read_counter <= read_counter + 18'd1;
			  
			//writing S' into upper half of RAM0
			we_1 <= 1'b1;
			  
			m2_s_state <= S_LEAN_IN_FETCH_2;
		end
  
		S_LEAN_IN_FETCH_2: begin
			//check if all 64 S' values of an 8x8 block in read
			if(fetch_counter < 8'd64) begin 
				SRAM_address <= in_offset + fetch_counter; 
				fetch_counter <= fetch_counter + 18'd1;
				read_counter <= read_counter + 18'd1;
				input_1 <= SRAM_read_data;
			end
			
			//match RAM0 address with corresponding S' value 
			if($signed(counter - 18'd1) < 18'd0) begin
				address1 <= 18'd0;
			end
			else begin
				address1 <= counter - 18'd1;
			end
			
			//state change
			if(counter < 8'd64) begin
				counter <= counter + 7'd1;
			    	m2_s_state <= S_LEAN_IN_FETCH_2;
			end
			else begin
				m2_s_state <= S_M2_TRANSITION_1;
			end
		end
    
		S_M2_TRANSITION_1: begin 
			//write the last T component into RAM0
			input_1 <= SRAM_read_data; 
			
			//done fetching, reset counters
			fetch_counter <= 18'd0;
			counter <= 7'd0;
		  
			m2_s_state <= S_M2_TRANSITION_2;
		end
		S_M2_TRANSITION_2: begin  
			//initialize address of RAM0
			address1 <= 18'd0; //even
		    	address2 <= 18'd1; //odd
		   
		    	we_1 <= 1'b0;
		 
		    	m2_s_state <= S_M2_TRANSITION_3;
	    	end
	    	S_M2_TRANSITION_3: begin 
			address1 <= address1 + 7'd2;
			address2 <= address2 + 7'd2;

			m2_s_state <= S_CT_1;
	    	end
		S_CT_1: begin   //T_counter = 0
			//temp_t[7:0] stores results of multiplications
			temp_t6 <= m1_res;
			temp_t7 <= m2_res;

			address1 <= address1 + 7'd2;
			address2 <= address2 + 7'd2;
			
			temp_t_even <= output_1;
			temp_t_odd <= output_2;

			T_counter <= T_counter + 8'd1;
    
			//calc and t_calc_counter need to be 0 at the beginning
			//increment after index 0 is processed
			if(calc != 8'd0)
			  calc <= calc +  8'd1;
			
			//get address of RAM1 ready to write 
			if(t_calc_counter != 8'd0)
			  address3 <= address3 + 7'd1;
			 
			//reset calc to go to the next row 
			if(calc == 8'd31)
			  calc <= 8'd0;

			m2_s_state <= S_CT_2;
   
		end
		S_CT_2: begin   //T_counter = 1
			temp_t0 <= m1_res;
			temp_t1 <= m2_res;
			
			address1 <= address1 + 7'd2;
			address2 <= address2 + 7'd2;
			
			temp_t_even <= output_1;
			temp_t_odd <= output_2;
			
			T_counter <= T_counter + 8'd1;
			calc <= calc +  8'd1;

			//write T value to second dual port memory
			if(t_calc_counter != 8'd0) begin
				we_3 <= 1'b1;
				input_3 <= ($signed(temp_t0) + $signed(temp_t1) + $signed(temp_t2) + $signed(temp_t3) + $signed(temp_t4) + $signed(temp_t5) + $signed(temp_t6) + $signed(temp_t7)) >>8;
		    	end
			
			//increment base so it goes to the next row
			if(calc == 16'd29)begin
				base_even <= base_even + 16'd8;
				base_odd <= base_odd + 16'd8;
			end

			m2_s_state <= S_CT_3;
		end
		S_CT_3: begin  //T_counter = 2
			temp_t2 <= m1_res;
			temp_t3 <= m2_res;
			
			address1 <= base_even;
			address2 <= base_odd;
			
			temp_t_even <= output_1; //S'6
			temp_t_odd <= output_2; //s'7
    
			if(T_counter <= 8'd2) 
			t_calc_counter <= t_calc_counter + 8'd1;

			T_counter <= T_counter + 8'd1;
			calc <= calc +  8'd1;
			
			we_3 <= 1'b0;
			
			m2_s_state <= S_CT_4;
   
		end
		S_CT_4: begin    //T_counter = 3
			temp_t4 <= m1_res;
			temp_t5 <= m2_res;

			address1 <= address1 + 7'd2;
			address2 <= address2 + 7'd2;
			
			temp_t_even <= output_1;
			temp_t_odd <= output_2;

			calc <= calc + 8'd1;
			
			T_counter <= 8'd0;
    
			if(t_calc_counter == 8'd64) 
				//all 64 elements of T matrix is done
				m2_s_state <= S_M2_TRANSITION_11;
			else
				m2_s_state <= S_CT_1;
		end
		S_M2_TRANSITION_11: begin  
			//initialize address of RAM1
			address3 <= 7'd1; //odd
			address4 <= 7'd0; //even
			
			//reset counters
			calc <= 8'd0;
			t_calc_counter <= 8'd0;
			base_even <= 16'd0;
			base_odd <= 16'd1;

			m2_s_state <= S_M2_TRANSITION_22;
		end
		S_M2_TRANSITION_22: begin  
			address3 <= address3 + 7'd2;
			address4 <= address4 + 7'd2;
			
			//check if all S' is read
			//when lead-out no fetch S' happens
			if(fetch_counter < 63 && lead_out == 1'b0)
			SRAM_address <= SRAM_address + 18'd1;
			
			//for getting C value form MUX below
			T_counter <= 8'd4;

		    	m2_s_state <= S_M2_TRANSITION_33;
		end
		S_M2_TRANSITION_33: begin 
			address3 <= address3 + 7'd2; //odd
			address4 <= address4 + 7'd2; //even
		  
			temp_s_even <= output_4;
			temp_s_odd <= output_3;
    
			if(fetch_counter < 63 && lead_out == 1'b0) begin
				SRAM_address <= SRAM_address + 18'd1;
				fetch_counter <= fetch_counter + 18'd1;
			end
    
			//initialize RAM0 address for fetching S'
			address1 <= 7'd0;
			counter <= counter + 7'd1;
			we_1 <= 1'b1;
			
			//change matrix C to C transpose
			transpose <= 1'b0;
			
			T_counter <= T_counter + 8'd1;
			
			//check if lead out takes place
			if(SRAM_address == 18'd230399)
				lead_out <= 1'b1;
  
			m2_s_state <= S_CS_FETCH_1;
		end
		S_CS_FETCH_1: begin   //T_counter = 4
			address3 <= address3 + 7'd2;
			address4 <= address4 + 7'd2;
			
			temp_s_even <= output_4;
			temp_s_odd <= output_3;
			
			temp_s0 <= m1_res;
			temp_s1 <= m2_res;
    
			//write S value to lower half of RAM0
			if(s_calc_counter != 8'd0) begin
				we_2 <= 1'b1;
		        	input_2 <= ($signed(temp_s0) + $signed(temp_s1) + $signed(temp_s2) + $signed(temp_s3) + $signed(temp_s4) + $signed(temp_s5) + $signed(temp_s6) + $signed(temp_s7)) >>16;
			end
			
			if($signed(counter - 18'd1) < 18'd0) begin
				address1 <= 18'd0;
			end
			else if(counter <= 8'd65) begin
				address1 <= counter - 18'd2;
			end
			if(counter < 8'd66) begin
				counter <= counter + 7'd1;
			end
    
			//check if all S' is read
			//when lead-out no fetch S' happens
			if(fetch_counter < 63 && lead_out == 1'b0) begin
				SRAM_address <= SRAM_address + 18'd1;
				fetch_counter <= fetch_counter + 18'd1;
				read_counter <= read_counter + 18'd1;
				input_1 <= SRAM_read_data;
			end
			else if(counter == 8'd66)
				we_1 <= 1'b0;

			T_counter <= T_counter + 8'd1;

			calc <= calc +  8'd1;
			
			m2_s_state <= S_CS_FETCH_2;
    
		end
		S_CS_FETCH_2: begin   //T_counter = 5
			address3 <= address3 + 7'd2; //odd
			address4 <= address4 + 7'd2; //even
			
			temp_s_even <= output_4;
			temp_s_odd <= output_3;
			
			temp_s2 <= m1_res;
			temp_s3 <= m2_res;
			
			we_2 <= 1'b0;
			
			//go to next column 
			if(calc == 16'd29)begin
				base_even <= base_even + 16'd8;
			 	base_odd <= base_odd + 16'd8;
			end

			if($signed(counter - 18'd1) < 18'd0) begin
				address1 <= 18'd0;
			end
			else if(counter <= 8'd65) begin
			    	address1 <= counter - 18'd2;
			end
			 
			if(counter < 8'd66) begin
			    	counter <= counter + 7'd1;
			end
    
			if(fetch_counter < 63) begin
				SRAM_address <= SRAM_address + 18'd1;
			    	fetch_counter <= fetch_counter + 18'd1;
			    	read_counter <= read_counter + 18'd1;			
			    	input_1 <= SRAM_read_data;
			end
			else if(counter == 8'd66)
			    	we_1 <= 1'b0;
      
			T_counter <= T_counter + 8'd1;
			calc <= calc +  8'd1;

			m2_s_state <= S_CS_FETCH_3;
    
		end
		S_CS_FETCH_3: begin   //T_counter = 6
			address4 <= base_even;
			address3 <= base_odd;
			
			temp_s_even <= output_4; 
			temp_s_odd <= output_3; 
			
			temp_s4 <= m1_res; 
			temp_s5 <= m2_res;
			
			we_2 <= 1'b1;
    
			if($signed(counter - 18'd1) < 18'd0)
			    	address1 <= 18'd0;
			else if(counter <= 8'd65)
				address1 <= counter - 18'd2;
				
			if(counter < 8'd66) 
			    	counter <= counter + 7'd1;
    
			if(fetch_counter < 63) begin
			  	SRAM_address <= SRAM_address + 18'd1;
			  	fetch_counter <= fetch_counter + 18'd1;
			  	read_counter <= read_counter + 18'd1;
			
			  	input_1 <= SRAM_read_data;
			  	//address1 <= address1 + 7'd1;
			end
			else if(counter == 8'd66)
			  	we_1 <= 1'b0;
    
			if(T_counter == 8'd7)
				T_counter <= 8'd4;
			  
			calc <= calc +  8'd1;
			
			m2_s_state <= S_CS_FETCH_4;
    
		end
		S_CS_FETCH_4: begin  //T_counter = 7
			address3 <= address3 + 7'd2;
			address4 <= address4 + 7'd2;
			
			temp_s_even <= output_4;
			temp_s_odd <= output_3;
			
			temp_s6 <= m1_res;
			temp_s7 <= m2_res;
			
			T_counter <= T_counter + 8'd1;
    
	/////////////////////////////////////////////////////////////////////////////////////////
			//write S value to the lower half of the first dual port memory
			//input_1 <= (temp_s0 + temp_s1 + temp_s2 + temp_s3 + temp_s4 + temp_s5 + temp_s6 + temp_s7) >>16;
    
			if(calc == 8'd31)
				calc <= 8'd0;
			else
			    	calc <= calc + 8'd1;

			address2 <= s_calc_counter + 8'd64;
			s_calc_counter <= s_calc_counter + 8'd1;
    
			if($signed(counter - 18'd1) < 18'd0)
			    	address1 <= 18'd0;
			else if(counter <= 8'd65)
			    	address1 <= counter - 18'd2;

			if(counter < 8'd66)
			    	counter <= counter + 7'd1;
    
			if(fetch_counter < 63) begin
				SRAM_address <= SRAM_address + 18'd1;
			    	fetch_counter <= fetch_counter + 18'd1;
			    	read_counter <= read_counter + 18'd1;
			    	input_1 <= SRAM_read_data;
			end
			else if(counter == 8'd66)
				we_1 <= 1'b0;
    
			if(s_calc_counter == 8'd63) begin
			    	s_calc_counter <= 8'd0; 
			    	m2_s_state <= S_M2_TRANSITION_111;
			end
			else
			    	m2_s_state <= S_CS_FETCH_1;
		end
		S_M2_TRANSITION_111: begin
		    	address1 <= 7'd64;
		    	address2 <= 7'd65;
		  	
		    	s_calc_counter <= 8'd0;
			
		    	//reset tranpose back for the next round of common case
		    	transpose <= 1'b1;
			
		    	//write the last S into RAM0
		    	we_2 <= 1'b1;
		    	input_2 <= ($signed(temp_s0) + $signed(temp_s1) + $signed(temp_s2) + $signed(temp_s3) + $signed(temp_s4) + $signed(temp_s5) + $signed(temp_s6) + $signed(temp_s7)) >>16;

              	    	m2_s_state <= S_M2_TRANSITION_222;
		end
		S_M2_TRANSITION_222: begin
		     	address1<= address1 + 7'd2;
		     	address2<= address2 + 7'd2;
      
		     	SRAM_address <= write_counter;
		     	we_n <= 1'b0;
		  
		     	fetch_counter <= 18'd0;
		  
		     	m2_s_state <= S_WS_1;
		end
		S_WS_1: begin
			address1<= address1 + 7'd2;
			address2<= address2 + 7'd2;
		  
			SRAM_address <= SRAM_address + 18'd1;
			write_counter <= write_counter + 18'd1;
		  
			SRAM_write_data <= {output_1[7:0],output_2[7:0]};
      
			if (write_counter == 18'd0)
				m2_s_state <= S_WS_1;
			else if((write_counter+18'd1) % 18'd64 != 18'd0 &&  write_counter != 18'd0)
				m2_s_state <= S_WS_1;
			else begin
				m2_s_state <= S_CT_1;
				we_n <= 1'b1;
				SRAM_address <= read_counter + in_offset + 18'd1;
			end
		end
    default: m2_s_state <= S_m2_IDLE;
    endcase
  end
end

always_comb begin
	if(T_counter == 8'd0)
		m2_C_state <= C_CT_1;
	else if(T_counter == 8'd1)
		m2_C_state <= C_CT_2;
	else if(T_counter == 8'd2)
		m2_C_state <= C_CT_3;
	else if(T_counter == 8'd3)
		m2_C_state <= C_CT_4;
	else if(T_counter == 8'd4)
		m2_C_state <= C_CS_FETCH_1;
	else if(T_counter == 8'd5)
		m2_C_state <= C_CS_FETCH_2;
	else if(T_counter == 8'd6)
		m2_C_state <= C_CS_FETCH_3;
	else if(T_counter == 8'd7)
		m2_C_state <= C_CS_FETCH_4;
	else 
		m2_C_state <= C_M2_BLANK;
    
	if(transpose == 1'b1) begin //used for computation of T
		if(calc == 8'd0) begin
		    	m1_op2 = 32'sd1448; //c0
		    	m2_op2 = 32'sd2008; //c8
		end
		else if(calc == 8'd1) begin
			m1_op2 = 32'sd1892; //c16
			m2_op2 = 32'sd1702; //c24
		end
		else if(calc == 8'd2) begin
			m1_op2 = 32'sd1448; //c32
			m2_op2 = 32'sd1137; //c40
		end
		else if(calc == 8'd3) begin
			m1_op2 = 32'sd783; //c48
			m2_op2 = 32'sd399; //c56
		end
		else if(calc == 8'd4) begin
			m1_op2 = 32'sd1448; //c1
			m2_op2 = 32'sd1702; //c9
		end
		else if(calc == 8'd5) begin
			m1_op2 = 32'sd783; //c17
			m2_op2 = -32'sd399; //c25
		end
		else if(calc == 8'd6) begin
			m1_op2 = -32'sd1448; //c33
			m2_op2 = -32'sd2008; //c41
		end
		else if(calc == 8'd7) begin
			m1_op2 = -32'sd1892; //c49
			m2_op2 = -32'sd1137; //c57  
		end
		else if(calc == 8'd8) begin
			m1_op2 = 32'sd1448; //c2
			m2_op2 = 32'sd1137; //c10
		end
		else if(calc == 8'd9) begin
			m1_op2 = -32'sd783; //c18
			m2_op2 = -32'sd2008; //c26
		end
		else if(calc == 8'd10) begin
			m1_op2 = -32'sd1448; //c34
			m2_op2 = -32'sd399; //c42
		end 
		else if(calc == 8'd11) begin
			m1_op2 = 32'sd1892; //c50
			m2_op2 = 32'sd1702; //c58
		end
		else if(calc == 8'd12) begin
			m1_op2 = 32'sd1448; //c3
			m2_op2 = 32'sd399; //c11
		end
		else if(calc == 8'd13) begin
			m1_op2 = -32'sd1892; //c19
			m2_op2 = -32'sd1137; //c27
		end  
		else if(calc == 8'd14) begin
			m1_op2 = 32'sd1448; //c35
			m2_op2 = 32'sd1702; //c43 
		end
		else if(calc == 8'd15) begin
			m1_op2 = -32'sd783; //c51
			m2_op2 = -32'sd2008;//c59
		end
		else if(calc == 8'd16) begin
			m1_op2 = 32'sd1448; //c4
			m2_op2 = -32'sd399; //c12
		end
		else if(calc == 8'd17) begin
			m1_op2 = -32'sd1892; //c20
			m2_op2 = 32'sd1137; //c28
		end
		else if(calc == 8'd18) begin
			m1_op2 = 32'sd1448; //c36
			m2_op2 = -32'sd1702; //c44
		end
		else if(calc == 8'd19) begin
			m1_op2 = -32'sd783; //c52
			m2_op2 = 32'sd2008; //c60
		end
		else if(calc == 8'd20) begin
			m1_op2 = 32'sd1448; //c5
			m2_op2 = -32'sd1137; //c13
		end
		else if(calc == 8'd21) begin
			m1_op2 = -32'sd783; //c21
			m2_op2 = 32'sd2008; //c29  
		end
		else if(calc == 8'd22) begin
			m1_op2 = -32'sd1448; //c37
			m2_op2 = -32'sd399; //c45 
		end
		else if(calc == 8'd23) begin
			m1_op2 = 32'sd1892; //c53
			m2_op2 = -32'sd1702; //c61
		end
		else if(calc == 8'd24) begin
			m1_op2 = 32'sd1448; //c6
			m2_op2 = -32'sd1702; //c14
		end 
		else if(calc == 8'd25) begin
			m1_op2 = 32'sd783; //c22
			m2_op2 = 32'sd399; //c30
		end 
		else if(calc == 8'd26) begin
			m1_op2 = -32'sd1448; //c38
			m2_op2 = 32'sd2008; //c46
		end
		else if(calc == 8'd27) begin
			m1_op2 = -32'sd1892; //c54
			m2_op2 = 32'sd1137; //c62
		end
		else if(calc == 8'd28) begin
			m1_op2 = 32'sd1448; //c7
			m2_op2 = -32'sd2008; //c15
		end
		else if(calc == 8'd29) begin
			m1_op2 = 32'sd1892; //c23
			m2_op2 = -32'sd1702; //c31
		end
		else if(calc == 8'd30) begin
			m1_op2 = 32'sd1448; //c39
			m2_op2 = -32'sd1137; //c47
		end
		else if(calc == 8'd31) begin
			m1_op2 = 32'sd783; //c55
			m2_op2 = -32'sd399; //c63
		end
		else begin
			m1_op2 = 32'sd0;
			m2_op2 = 32'sd0;
		end
    
	end
	else begin  //used for computation of S
		if(calc == 8'd0) begin
			m1_op2 = 32'd1448; //c0
			m2_op2 = 32'd1448; //c1
		end
		else if(calc == 8'd1) begin
			m1_op2 = 32'd1448; //c2
			m2_op2 = 32'd1448; //c3
		end
		else if(calc == 8'd2) begin
			m1_op2 = 32'd1448; //c4
			m2_op2 = 32'd1448; //c5
		end
		else if(calc == 8'd3) begin
			m1_op2 = 32'd1448; //c6
			m2_op2 = 32'd1448; //c7
		end
		else if(calc == 8'd4) begin
			m1_op2 = 32'd2008; //c8
			m2_op2 = 32'd1702; //c9
		end
		else if(calc == 8'd5) begin
			m1_op2 = 32'd1137; //c10
			m2_op2 = 32'd399; //c11
		end
		else if(calc == 8'd6) begin
			m1_op2 = -32'd399; //c12
			m2_op2 = -32'd1137; //c13
		end
		else if(calc == 8'd7) begin
			m1_op2 = -32'd1702; //c14
			m2_op2 = -32'd2008; //c15  
		end
		else if(calc == 8'd8) begin
			m1_op2 = 32'd1892; //16
			m2_op2 = 32'd783; //17
		end
		else if(calc == 8'd9) begin
			m1_op2 = -32'd783; //18
			m2_op2 = -32'd1892; //19
		end
		else if(calc == 8'd10) begin
			m1_op2 = -32'd1892; //20
			m2_op2 = -32'd783; //21
		end 
		else if(calc == 8'd11) begin
			m1_op2 = 32'd783; //22
			m2_op2 = 32'd1892; //23
		end
		else if(calc == 8'd12) begin
			m1_op2 = 32'd1702; //24
			m2_op2 = -32'd399; //25
		end
		else if(calc == 8'd13) begin
			m1_op2 = -32'd2008; //26
			m2_op2 = -32'd1137; //27
		end  
		else if(calc == 8'd14) begin
			m1_op2 = 32'd1137; //28
			m2_op2 = 32'd2008; //29  
		end
		else if(calc == 8'd15) begin
			m1_op2 = 32'd399; //30
			m2_op2 = -32'd1702;//31
		end
		else if(calc == 8'd16) begin
			m1_op2 = 32'd1448; //32
			m2_op2 = -32'd1448; //33
		end
		else if(calc == 8'd17) begin
			m1_op2 = -32'd1448; //34
			m2_op2 = 32'd1448; //35
		end
		else if(calc == 8'd18) begin
			m1_op2 = 32'd1448; //36
			m2_op2 = -32'd1448; //37
		end
		else if(calc == 8'd19) begin
			m1_op2 = -32'd1448; //38
			m2_op2 = 32'd1448; //39
		end
		else if(calc == 8'd20) begin
			m1_op2 = -32'd1137; //40
			m2_op2 = -32'd2008; //41
		end
		else if(calc == 8'd21) begin
			m1_op2 = 32'd399; //42
			m2_op2 = 32'd1702; //43  
		end
		else if(calc == 8'd22) begin
			m1_op2 = -32'd1702; //44
			m2_op2 = -32'd399; //45 
		end
		else if(calc == 8'd23) begin
			m1_op2 = 32'd2008; //46
			m2_op2 = -32'd1137; //47
		end
		else if(calc == 8'd24) begin
			m1_op2 = 32'd783; //48
			m2_op2 = -32'd1892; //49
		end 
		else if(calc == 8'd25) begin
			m1_op2 = 32'd1892; //50
			m2_op2 = -32'd783; //51
		end 
		else if(calc == 8'd26) begin
			m1_op2 = -32'd783; //52
			m2_op2 = 32'd1892; //53
		end
		else if(calc == 8'd27) begin
			m1_op2 = -32'd1892; //54
			m2_op2 = 32'd783; //55
		end
		else if(calc == 8'd28) begin
			m1_op2 = 32'd399; //56
			m2_op2 = -32'd1137; //57
		end
		else if(calc == 8'd29) begin
			m1_op2 = 32'd1702; //58
		  m2_op2 = -32'd2008; //59
		end
		else if(calc == 8'd30) begin
			m1_op2 = 32'd2008; //60
			m2_op2 = -32'd1702; //61
		end
		else if(calc == 8'd31) begin
			m1_op2 = 32'd1137; //62
			m2_op2 = -32'd399; //63
		end
		else begin
			m1_op2 = 32'd0;
			m2_op2 = 32'd0;
		end
	end 
	case(m2_C_state)
		C_M2_BLANK: begin
		m1_op1 = 32'd0;
		m1_op2 = 32'd0;
		m2_op1 = 32'd0;
		m2_op2 = 32'd0;
    	end
    	C_CT_1: begin
		m1_op1 = $signed(temp_t_even);
		m2_op1 = $signed(temp_t_odd);
    	end  
    	C_CT_2: begin
		m1_op1 = $signed(temp_t_even);
		m2_op1 = $signed(temp_t_odd);
    	end
    	C_CT_3: begin
		m1_op1 = $signed(temp_t_even);
		m2_op1 = $signed(temp_t_odd);
    	end
    	C_CT_4: begin
		m1_op1 = $signed(temp_t_even);
		m2_op1 = $signed(temp_t_odd);
    	end
    	C_CS_FETCH_1: begin
		m1_op1 = $signed(temp_s_even);
		m2_op1 = $signed(temp_s_odd);
    	end
    	C_CS_FETCH_2: begin
		m1_op1 = $signed(temp_s_even);
		m2_op1 = $signed(temp_s_odd);
    	end
    	C_CS_FETCH_3: begin
		m1_op1 = $signed(temp_s_even);
		m2_op1 = $signed(temp_s_odd);
    	end
    	C_CS_FETCH_4: begin
		m1_op1 = $signed(temp_s_even);
		m2_op1 = $signed(temp_s_odd);
    	end
    default: m2_C_state <= C_M2_BLANK;
  endcase
end
endmodule 