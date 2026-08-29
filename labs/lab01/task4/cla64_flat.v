// cla64_flat.v
// Flat 64-bit carry-lookahead adder.
//
// The carry function below computes each carry directly from all required
// propagate/generate terms. Each carry output has an explicit #(2) delay.

module cla64_flat(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [63:0] p, g;
  wire [64:1] c;

  // Generate / propagate
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : gen_pg
      xor #(2) (p[i], a[i], b[i]);
      and #(2) (g[i], a[i], b[i]);
    end
  endgenerate

  // Direct carry-lookahead calculation.
  // For c[k]:
  // c[k] = g[k-1]
  //      | p[k-1]g[k-2]
  //      | p[k-1]p[k-2]g[k-3]
  //      | ...
  //      | p[k-1]...p[0]cin
  function automatic calc_carry;
    input [63:0] p_in;
    input [63:0] g_in;
    input        cin_in;
    input integer k;

    integer j;
    reg prod;
    reg result;

    begin
      result = g_in[k-1];
      prod   = 1'b1;

      for (j = k-1; j > 0; j = j - 1) begin
        prod   = prod & p_in[j];
        result = result | (prod & g_in[j-1]);
      end

      prod   = prod & p_in[0];
      result = result | (prod & cin_in);

      calc_carry = result;
    end
  endfunction

  // Generate c[1] through c[64], each with an explicit delay.
  genvar k;
  generate
    for (k = 1; k <= 64; k = k + 1) begin : gen_carries
      assign #(2) c[k] = calc_carry(p, g, cin, k);
    end
  endgenerate

  // Final carry
  assign #(2) cout = c[64];

  // Sum bits: sum[i] = p[i] XOR c[i], with c[0] = cin
  assign #(2) sum = p ^ {c[63:1], cin};

endmodule