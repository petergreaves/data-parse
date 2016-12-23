package com.easyjet.fcp.test.io;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;

import com.easyjet.fcp.test.domain.FlightSchedule;
import com.easyjet.fcp.test.util.FlightScheduleParseException;

public class ScheduleWriter implements IScheduleWriter {

	private String path;

	private String dateInFormatString;
	private String dateOutFormatString;
	private String keyFormatString;
	private String flightLiteralValue;
	private String scheduledLiteralValue;
	

	private String carrierCodeFrom;
	private String carrierCodeTo;

	private static final Logger logger = Logger.getRootLogger();

	public ScheduleWriter() {

	}

	public String getPath() {
		return path;
	}

	public void setPath(String path) {
		this.path = path;
	}

	@Override
	public void write(List<FlightSchedule> schedules) {

		int schedulesWritten = 0;
		int flightCount = schedules.size();
		logger.info("Number of flight schedules to write : " + flightCount);
		
		try (FileWriter fw = new FileWriter(new File(path))) {

	
			boolean writeThis = true;


			Iterator<FlightSchedule> it = schedules.iterator();
			FlightSchedule sched = null;
			while (it.hasNext()) {

				sched = it.next();

				writeThis = true;
				String f = null;
				try {
					f = getFormattedFlight(sched);
				} catch (FlightScheduleParseException e) {

					writeThis = false;
				}

				if (writeThis && null != f) { // no parse exception
					fw.write(f);
					fw.write(System.lineSeparator());
					fw.flush();
					schedulesWritten++;
				}

				
				if (schedulesWritten % 100 == 0) {
					logger.debug("Flight schedules written : " + schedulesWritten + " of " + flightCount);

				}

			}

		} catch (IOException e) {
			logger.error(e.getMessage());
		}
		logger.debug("Done.  Flight schedules written : " + schedulesWritten + " of " + flightCount);
	}

	private String getFormattedFlight(FlightSchedule flight) throws FlightScheduleParseException {

		String cc = flight.getCarrierCode().replace("\"", "");

		if (cc.equals(carrierCodeFrom)) {

			cc = carrierCodeTo;
		}

		String flightKey = getFlightKey(flight);

		logger.debug("Writing data for flightKey : " + flightKey);

		String flightDepDT = getFlightDT(flight.getLocalDepDtTm());
		String flightArrivalDT = getFlightDT(flight.getLocalArrDtTm());

		String result = String.format(";%1$s;%2$s;%3$s;%4$s;%5$s;%6$s;%7$s;%8$s;%9$s;%10$s;%11$s;%12$s;;%13$s;",
				flightKey, flight.getFlightNumber().replace("\"", ""), flightDepDT, flightArrivalDT, flightDepDT,
				flightArrivalDT, flightDepDT, flightArrivalDT, flightLiteralValue, scheduledLiteralValue,
				(flight.getDepAirportCode() + flight.getArrAirportCode()).replaceAll("\"", ""), cc,
				flight.getAircraftType().replace("\"", ""));

		return result;

	}

	private String getFlightKey(FlightSchedule flight) throws FlightScheduleParseException {

		StringBuffer flightKey = new StringBuffer();

		String localDepDateTime = flight.getLocalDepDtTm().replace("\"", "");
		DateFormat inFormat = new SimpleDateFormat(dateInFormatString);

		DateFormat flightKeyFormat = new SimpleDateFormat(keyFormatString);

		Date d = null;
		String dt = null;

		try {
			d = inFormat.parse(localDepDateTime);
			dt = flightKeyFormat.format(d);

		} catch (ParseException pe) {
			String ex = "Could not parse date : " + localDepDateTime;
			logger.error(ex);
			throw new FlightScheduleParseException(ex);
		}
		flightKey.append(dt);
		flightKey.append(flight.getDepAirportCode().replace("\"", ""));
		flightKey.append(flight.getArrAirportCode().replace("\"", ""));
		flightKey.append(flight.getFlightNumber().replace("\"", ""));
		return flightKey.toString();
	}

	private String getFlightDT(String dt) throws FlightScheduleParseException {

		String localDateTime = dt.replace("\"", "");
		DateFormat inFormat = new SimpleDateFormat(dateInFormatString);

		DateFormat outFormat = new SimpleDateFormat(dateOutFormatString);

		Date d = null;
		String formatted = null;

		try {
			d = inFormat.parse(localDateTime);
			formatted = outFormat.format(d);

		} catch (ParseException pe) {

			String ex = "Could not parse date : " + localDateTime;
			logger.error(ex);
			throw new FlightScheduleParseException(ex);
		}

		return formatted;

	}

	public String getDateInFormatString() {
		return dateInFormatString;
	}

	public void setDateInFormatString(String dateInFormatString) {
		this.dateInFormatString = dateInFormatString;
	}

	public String getDateOutFormatString() {
		return dateOutFormatString;
	}

	public String getKeyFormatString() {
		return keyFormatString;
	}

	public void setKeyFormatString(String keyFormatString) {
		this.keyFormatString = keyFormatString;
	}

	public void setDateOutFormatString(String dateOutFormatString) {
		this.dateOutFormatString = dateOutFormatString;
	}

	public String getCarrierCodeFrom() {
		return carrierCodeFrom;
	}

	public void setCarrierCodeFrom(String carrierCodeFrom) {
		this.carrierCodeFrom = carrierCodeFrom;
	}

	public String getCarrierCodeTo() {
		return carrierCodeTo;
	}

	public void setCarrierCodeTo(String carrierCodeTo) {
		this.carrierCodeTo = carrierCodeTo;
	}

	public String getFlightLiteralValue() {
		return flightLiteralValue;
	}

	public void setFlightLiteralValue(String flightLiteralValue) {
		this.flightLiteralValue = flightLiteralValue;
	}

	public String getScheduledLiteralValue() {
		return scheduledLiteralValue;
	}

	public void setScheduledLiteralValue(String scheduledLiteralValue) {
		this.scheduledLiteralValue = scheduledLiteralValue;
	}
}
