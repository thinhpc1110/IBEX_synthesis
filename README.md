# IBEX_synthesis
![Screenshot 2024-08-24 131239](https://github.com/user-attachments/assets/3ccd6b97-083b-477d-ab0d-6f11d8c88e3b)
Trên đây là ví dụ mà trình biên dịch của Cadence Genus thông báo lỗi của file thiết kế, có thể thấy nó thông báo rằng là cái Macro "DV_FCOV_SIGNAL" đang không xác định ở trong file ibex_controller.sv dòng 904. 
![Screenshot 2024-08-24 135004](https://github.com/user-attachments/assets/eb3b946a-95b8-4a4d-b2ee-7c09c0bc878f)
Tìm đến đúng vị trí lỗi mà trình biên dịch thông báo ta sẽ thấy là xuất hiện DV_FCOV_SIGNAl tuy nhiên kiểm tra trong toàn bộ file rtl thì không thấy xuất hiện syntax system verilog nào tham chiếu đến file DV_FCOV_SIGNAL, do vậy cách sửa là phải thêm tham chiếu đến file DV_FCOV.
Dưới đây là cách sửa:
![Screenshot 2024-08-24 135056](https://github.com/user-attachments/assets/f6441f5b-c847-42fb-971b-1a192d8fc436)
Tương tự như vậy đối với các lỗi khác mà trình biên dịch thông báo.
