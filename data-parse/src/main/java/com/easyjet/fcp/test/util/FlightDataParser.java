package com.easyjet.fcp.test.util;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;
import org.springframework.util.StringUtils;

import com.easyjet.fcp.test.domain.Fare;
import com.easyjet.fcp.test.domain.FlightSchedule;

public class FlightDataParser implements IDataParser {

	protected static final String FLIGHT_SCHEDULE_PREFIX = "EXEC dbo.CreateFlightScheduleWithCapacity ";
	protected static final String FLIGHT_FARE_PREFIX = "EXEC dbo.CreateFlightFareWithFlightKey ";

	private static final Logger logger = Logger.getRootLogger();

	private List<Fare> fares = null;
	private List<FlightSchedule> schedules = null;

	public void dispatch(String line) {

		boolean isSchedule = false;
		boolean isFare = false;
		if (line.startsWith(FLIGHT_SCHEDULE_PREFIX)) {
			isSchedule = true;

		} else if (line.startsWith(FLIGHT_FARE_PREFIX)) {
			isFare = true;

		}
		if (isSchedule) {

			addToFlightSchedules(StringUtils.commaDelimitedListToStringArray(line));
		} else if (isFare) {
			addToFares(StringUtils.commaDelimitedListToStringArray(line));
		} else {

			logger.debug("Ignoring non-data line : " + line);
		}
	}

	private void addToFlightSchedules(String[] ar) {

		FlightSchedulerMap map = new FlightSchedulerMap(ar);
		FlightSchedule sched = new FlightSchedule(map);

		if (null == schedules) {

			schedules = new ArrayList<FlightSchedule>();
		}
		schedules.add(sched);

		
	}

	private void addToFares(String[] ar) {

		FareMap map = new FareMap(ar);
		Fare fare = new Fare(map);

		if (null == fares) {

			fares = new ArrayList<Fare>();
		}
		fares.add(fare);
		// logger.info("Adding to Fares : " + fare);
	}

	@Override
	public List<Fare> getFares() {

		return fares;
	}

	@Override
	public List<FlightSchedule> getFlightSchedules() {

		return schedules;
	}

}
