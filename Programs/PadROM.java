import java.io.*;

public class PadROM {
	public static void main(String[] args) {
		try {
			FileInputStream fis = new FileInputStream(args[0]);
			FileOutputStream fos = new FileOutputStream("rom.bin");
			for(int i = 0; i < 0x0400; i++) {
				fos.write(0);
			}
			char c1 = ' ';
			char c2 = ' ';
			while(fis.available() > 0) {
				int i = fis.read();
				if(c2 == 'E' && c1 == 'O' && (char)i == 'F') {
					break;
				}
				c2 = c1;
				c1 = (char)i;
				fos.write(i);
			}
			fos.close();
			fis.close();
		}catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
