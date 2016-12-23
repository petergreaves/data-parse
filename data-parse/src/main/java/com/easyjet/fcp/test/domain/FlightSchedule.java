package com.easyjet.fcp.test.domain;

import com.easyjet.fcp.test.util.FlightSchedulerMap;

public class FlightSchedule {

	private String aircraftType;
	private String carrierCode;
	private String flightNumber;
	private String localDepDtTm;
	private String localArrDtTm;
	private String depAirportCode;
	private String arrAirportCode;
	private String seatsSold;
	private String checkInStatus;
	private String depTerminalCode;
	private String arrTerminalCode;
	private String postedToAccounting;
	private String capacity;
	private String lid;

	public FlightSchedule(FlightSchedulerMap map) {

		this.setAircraftType(map.get(FlightSchedulerMap.AIRCRAFT_TYPE_KEY));
		this.setCarrierCode(map.get(FlightSchedulerMap.CARRIER_CODE_KEY));
		this.setFlightNumber(map.get(FlightSchedulerMap.FLIGHT_NUMBER_KEY));
		this.setLocalDepDtTm(map.get(FlightSchedulerMap.LOCAL_DEP_DT_KEY));
		this.setLocalArrDtTm(map.get(FlightSchedulerMap.LOCAL_ARR_DT_KEY));
		this.setDepAirportCode(map.get(FlightSchedulerMap.DEP_AIRPORT_CODE_KEY));
		this.setArrAirportCode(map.get(FlightSchedulerMap.ARR_AIRPORT_CODE_KEY));
		this.setSeatsSold(map.get(FlightSchedulerMap.SEATSSOLD_KEY));
		this.setCheckInStatus(map.get(FlightSchedulerMap.CHECKIN_STATUS_KEY));
		this.setDepTerminalCode(map.get(FlightSchedulerMap.DEP_TERM_CODE_KEY));
		this.setArrTerminalCode(map.get(FlightSchedulerMap.ARR_TERM_CODE_KEY));
		this.setPostedToAccounting(map.get(FlightSchedulerMap.POSTED_TO_ACC_KEY));
		this.setCapacity(map.get(FlightSchedulerMap.CAPACITY_KEY));
		this.setLid(map.get(FlightSchedulerMap.LID_KEY));

	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((flightNumber == null) ? 0 : flightNumber.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		FlightSchedule other = (FlightSchedule) obj;
		if (flightNumber == null) {
			if (other.flightNumber != null)
				return false;
		} else if (!flightNumber.equals(other.flightNumber))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "FlightSchedule [aircraftType=" + aircraftType + ", carrierCode=" + carrierCode + ", flightNumber="
				+ flightNumber + ", localDepDtTm=" + localDepDtTm + ", localArrDtTm=" + localArrDtTm
				+ ", depAirportCode=" + depAirportCode + ", arrAirportCode=" + arrAirportCode + ", seatsSold="
				+ seatsSold + ", checkInStatus=" + checkInStatus + ", depTerminalCode=" + depTerminalCode
				+ ", arrTerminalCode=" + arrTerminalCode + ", postedToAccounting=" + postedToAccounting + ", capacity="
				+ capacity + ", lid=" + lid + "]";
	}

	public String getAircraftType() {
		return aircraftType;
	}

	public void setAircraftType(String aircraftType) {
		this.aircraftType = aircraftType;
	}

	public String getCarrierCode() {
		return carrierCode;
	}

	public void setCarrierCode(String carrierCode) {
		this.carrierCode = carrierCode;
	}

	public String getFlightNumber() {
		return flightNumber;
	}

	public void setFlightNumber(String flightNumber) {
		this.flightNumber = flightNumber;
	}

	public String getLocalDepDtTm() {
		return localDepDtTm;
	}

	public void setLocalDepDtTm(String localDepDtTm) {
		this.localDepDtTm = localDepDtTm;
	}

	public String getLocalArrDtTm() {
		return localArrDtTm;
	}

	public void setLocalArrDtTm(String localArrDtTm) {
		this.localArrDtTm = localArrDtTm;
	}

	public String getDepAirportCode() {
		return depAirportCode;
	}

	public void setDepAirportCode(String depAirportCode) {
		this.depAirportCode = depAirportCode;
	}

	public String getArrAirportCode() {
		return arrAirportCode;
	}

	public void setArrAirportCode(String arrAirportCode) {
		this.arrAirportCode = arrAirportCode;
	}

	public String getSeatsSold() {
		return seatsSold;
	}

	public void setSeatsSold(String seatsSold) {
		this.seatsSold = seatsSold;
	}

	public String getCheckInStatus() {
		return checkInStatus;
	}

	public void setCheckInStatus(String checkInStatus) {
		this.checkInStatus = checkInStatus;
	}

	public String getDepTerminalCode() {
		return depTerminalCode;
	}

	public void setDepTerminalCode(String depTerminalCode) {
		this.depTerminalCode = depTerminalCode;
	}

	public String getArrTerminalCode() {
		return arrTerminalCode;
	}

	public void setArrTerminalCode(String arrTerminalCode) {
		this.arrTerminalCode = arrTerminalCode;
	}

	public String getPostedToAccounting() {
		return postedToAccounting;
	}

	public void setPostedToAccounting(String postedToAccounting) {
		this.postedToAccounting = postedToAccounting;
	}

	public String getCapacity() {
		return capacity;
	}

	public void setCapacity(String capacity) {
		this.capacity = capacity;
	}

	public String getLid() {
		return lid;
	}

	public void setLid(String lid) {
		this.lid = lid;
	}
}
