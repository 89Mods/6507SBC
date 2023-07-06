import java.io.*;

public class PadVGM {
	public static void main(String[] args) {
		try {
			FileInputStream fis = new FileInputStream(args[0]);
			fis.skip(0x40);
			int max = 0;
			int counter = 0;
			while(fis.available() > 0) {
				int i = fis.read();
				if(i == 0x50) {
					fis.read();
					counter += 1;
				}
				if(i == 0x63 || i == 0x62 || i == 0x61) {
					if(i == 0x61) {
						fis.read();
						fis.read();
					}
					if(counter > max) max = counter;
					counter = 0;
				}
				if(i == 0x66) break;
			}
			fis.close();
			System.out.println(max);
			fis = new FileInputStream(args[0]);
			FileOutputStream fos = new FileOutputStream("fixed.vgm");
			for(int i = 0; i < 0x40; i++) fos.write(fis.read());
			counter = 0;
			int last = 0;
			while(fis.available() > 0) {
				int i = fis.read();
				if(i == 0x50) {
					fos.write(i);
					last = fis.read();
					fos.write(last);
					counter += 1;
				}
				if(i == 0x63 || i == 0x62 || i == 0x61) {
					if(counter < max) {
						fos.write(0xFF);
						fos.write(max - counter);
					}
					counter = 0;
					fos.write(i);
					if(i == 0x61) {
						fos.write(fis.read());
						fos.write(fis.read());
						//int delay = fis.read() & 0xFF;
						//delay |= (fis.read() & 0xFF) << 8;
						//delay += delay >> 1;
						//fos.write(0x61);
						//fos.write(delay & 0xFF);
						//fos.write(delay >> 8);
						/*int a = delay / 735;
						for(int j = 0; j < a; j++) {
							fos.write(0xFF);
							fos.write(max);
							fos.write(0x62);
						}
						int b = delay - a * 735;
						if(b > 0) {
							int c = (int)((double)a / 735.0 * (double)max);
							if(c > 0) {
								fos.write(0xFF);
								fos.write(c);
							}
						}
						fos.write(0x61);
						fos.write(b & 0xFF);
						fos.write(b >> 8);*/
					}
				}
				if(i == 0x66) {
					fos.write(i);
					while(fis.available() > 0) fos.write(fis.read());
					break;
				}
			}
			fos.close();
			fis.close();
		}catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
