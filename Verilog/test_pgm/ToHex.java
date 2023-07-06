import java.io.*;

public class ToHex {
	public static void main(String[] args) {
		try {
			FileInputStream fis = new FileInputStream(args[0]);
			BufferedWriter bw = new BufferedWriter(new FileWriter(new File(args[0] + ".txt")));
			while(fis.available() > 0) {
				int i = fis.read();
				bw.write(String.format("%02x\n", i));
			}
			fis.close();
			bw.close();
		}catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
