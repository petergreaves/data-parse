package com.easyjet.fcp.test.io;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DecimalFormat;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;

import com.easyjet.fcp.test.domain.Fare;

public class FareWriter implements IFareWriter{

	private String path;
	
	private static final Logger logger = Logger.getRootLogger();
	
	public FareWriter(String path){
		this.setPath(path);
		
	}
	
	public String getPath() {
		return path;
	}
	public void setPath(String path) {
		this.path = path;
	}
	
	@Override
	public void write(List<Fare> fares) {
	
		
		try (FileWriter fw=new FileWriter(new File(path))){
			
			int k =0;
			int fareCount = fares.size();
			logger.debug("Number of fares to write : " +fareCount);
		
			Iterator<Fare> it = fares.iterator();
			Fare fare = null;
			while (it.hasNext()) {
				
				fare = it.next();
				fw.write(getFormattedFare(fare));
				if (k<fareCount){
					
					fw.write(System.lineSeparator());
				}
				fw.flush();
				k++;
				
				if (k%100 == 0){
					logger.info("Fares written : " +k);
					
				}
	            
	        }

			
	    } catch (IOException e) {
	        logger.error(e.getMessage());
	    }

		
	}
	
	private String getFormattedFare(Fare f){
		
		
		//CurrencyCode,AUmin,SeatsSold,ExtendedPrice, AU, SpecialFareCodeDesc, FlightKey, FareClassCode
		DecimalFormat df = new DecimalFormat("#.##");
		String extendedPriceFormatted = df.format(f.getExtendedPrice());

		String result = String.format("%1$s,%2$s,%3$s,%4$s,%5$s,%6$s",
				f.getCurrencyCode(),
				f.getAUmin(),
				f.getSeatsSold(),
				extendedPriceFormatted,
				f.getAU(),
				f.getFlightKey());
		
		return result;
		
		
	}
			
			
}
