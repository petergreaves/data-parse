package com.easyjet.fcp.test.domain;

import com.easyjet.fcp.test.util.FareMap;

public class Fare {
	
	public Fare(FareMap map){
		
		this.setAU(map.get(FareMap.AU_KEY));
		this.setCurrencyCode(map.get(FareMap.CURRENCY_CODE_KEY));
		this.setAUmin(map.get(FareMap.AUMIN_KEY));
		
		Double d =Double.parseDouble(map.get(FareMap.EXTENDED_PRICE_KEY));
		this.setExtendedPrice(d.doubleValue());
		
		this.setFareClassCode(map.get(FareMap.FARE_CLASS_CODE_KEY));

		this.setFlightKey(map.get(FareMap.FLIGHT_KEY_KEY));
		this.setSeatsSold(map.get(FareMap.SEATS_SOLD_KEY));
		this.setSpecialFareCodeDesc(map.get(FareMap.SPECIAL_FARE_DESC_KEY));
		
	}
	
	
	
	 private String fareClassCode;       
	 public String getFareClassCode() {
		return fareClassCode;
	}
	public void setFareClassCode(String fareClassCode) {
		this.fareClassCode = fareClassCode;
	}
	public String getCurrencyCode() {
		return currencyCode;
	}
	public void setCurrencyCode(String currencyCode) {
		this.currencyCode = currencyCode;
	}
	public Double getExtendedPrice() {
		return extendedPrice;
	}
	public void setExtendedPrice(Double extendedPrice) {
		this.extendedPrice = extendedPrice;
	}
	public String getFlightKey() {
		return flightKey;
	}
	public void setFlightKey(String flightKey) {
		this.flightKey = flightKey;
	}
	public String getSpecialFareCodeDesc() {
		return specialFareCodeDesc;
	}
	public void setSpecialFareCodeDesc(String specialFareCodeDesc) {
		this.specialFareCodeDesc = specialFareCodeDesc;
	}
	public String getAUmin() {
		return aUmin;
	}
	public void setAUmin(String aUmin) {
		this.aUmin = aUmin;
	}
	public String getAU() {
		return aU;
	}
	public void setAU(String aU) {
		this.aU = aU;
	}
	public String getSeatsSold() {
		return seatsSold;
	}
	public void setSeatsSold(String seatsSold) {
		this.seatsSold = seatsSold;
	}
	private String currencyCode;
	 private Double extendedPrice;
	 private String flightKey;
	 private String specialFareCodeDesc;
	 private String aUmin;
	 private String aU ;
	 private String seatsSold;
	@Override
	public String toString() {
		return "Fare [fareClassCode=" + fareClassCode + ", currencyCode=" + currencyCode + ", extendedPrice="
				+ extendedPrice + ", flightKey=" + flightKey + ", specialFareCodeDesc=" + specialFareCodeDesc
				+ ", aUmin=" + aUmin + ", aU=" + aU + ", seatsSold=" + seatsSold + "]";
	}
}