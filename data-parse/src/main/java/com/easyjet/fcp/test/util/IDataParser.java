package com.easyjet.fcp.test.util;

import java.util.List;

import com.easyjet.fcp.test.domain.Fare;
import com.easyjet.fcp.test.domain.FlightSchedule;

public interface IDataParser {
void dispatch(String s);

List<Fare> getFares();
List<FlightSchedule> getFlightSchedules();

}
