import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;

public class BitmapConv {
	public static void main(String[] args) {
		try {
			if(args.length < 1) {
				System.err.println("Must provide input file");
				System.exit(1);
			}
			BufferedImage img = ImageIO.read(new File(args[0]));
			if(img.getWidth() != 128 || img.getHeight() != 64) {
				System.err.println("Image must be 128x64 pixels");
				System.exit(1);
			}
			System.out.println("bitmap:");
			System.out.print(".byte ");
			for(int j = 0; j < 8; j++) {
				for(int i = 127; i >= 0; i--) {
					int a = 0;
					for(int k = 0; k < 8; k++) {
						a <<= 1;
						int rgb = img.getRGB(i, j * 8 + k);
						if((rgb & 0xFF) > 127) a |= 1;
					}
					System.out.print(String.format("$%02x", a));
					if(i != 0) System.out.print(", ");
					else {
						System.out.println();
						if(j != 7) System.out.print(".byte ");
					}
				}
			}
		}catch(Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}
}
