types : begin of ty_data,
c1 type i,
c2 type i,
c3 type i,
c4 type i,
end of ty_data.
types:tt_data type table of ty_data with empty key.

types : begin of ty_data4,
c1 type i,
c2 type i,
end of ty_data4,
tt_data4 type table of ty_data4 with empty key.

data(it_data) = value tt_data( for i = 1 then i + 10 until i > 50 
                                ( c1 = i c2 = i+2 c3 = i+3 c4 = i+4 ) ).

data(it_data2) = value tt_data( for wa in it_data where ( c1 > 30 ) ( wa ) ).

data(it_data3) = value tt_data( for wa in it_data index into lv_index where c1 = 20 ( lines of it_data from lv_index ) ).

data(it_data4) = value tt_data4( for wa in it_data from 2 to 5 ( c1 = wa-c1 c2 = wa-c2 ) ).
##################
one column table

types: tt_i type table of i with empty key.
data(it_data5) = value tt_i( for wa in it_data ( wa-c1 )).
##################

cl_demo_output=>display( it_data4 ).
