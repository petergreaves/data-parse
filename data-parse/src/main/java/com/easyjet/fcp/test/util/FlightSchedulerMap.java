package com.easyjet.fcp.test.util;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class FlightSchedulerMap  implements java.util.Map<String, String>{

	private Map<String, String> map;
	
	
	public static final String AIRCRAFT_TYPE_KEY = "AircraftType";
	public static final String CARRIER_CODE_KEY = "CarrierCode";
	public static final String FLIGHT_NUMBER_KEY = "FlightNumber";
	public static final String LOCAL_DEP_DT_KEY = "LocalDepDtTm";
	public static final String LOCAL_ARR_DT_KEY = "LocalArrDtTm";
	public static final String DEP_AIRPORT_CODE_KEY = "DepAirportCode";
	public static final String ARR_AIRPORT_CODE_KEY = "ArrAirportCode";
	public static final String SEATSSOLD_KEY = "SeatsSold";
	public static final String CHECKIN_STATUS_KEY = "CheckInStatus";
	public static final String DEP_TERM_CODE_KEY = "DepTerminalCode";
	public static final String ARR_TERM_CODE_KEY = "ArrTerminalCode";
	public static final String POSTED_TO_ACC_KEY = "PostedToAccounting";
	public static final String CAPACITY_KEY = "Capacity";
	public static final String LID_KEY = "Lid";
	
	
	private final String[] keys = {AIRCRAFT_TYPE_KEY,CARRIER_CODE_KEY,FLIGHT_NUMBER_KEY,LOCAL_DEP_DT_KEY,
							 LOCAL_ARR_DT_KEY,DEP_AIRPORT_CODE_KEY,ARR_AIRPORT_CODE_KEY,SEATSSOLD_KEY,
							 CHECKIN_STATUS_KEY,DEP_TERM_CODE_KEY,ARR_TERM_CODE_KEY,POSTED_TO_ACC_KEY,
							 CAPACITY_KEY,LID_KEY};
	
	
	
	public FlightSchedulerMap(String[] ar){
		

		for (int k=0;k<ar.length;k++){
			
			put(keys[k], ar[k]);
		}
		
	}
	
	@Override
	public String toString() {
		return "FlightSchedulerMap [map=" + map + "]";
	}

	public String put(String key, String value){
		
		if (null == map){
			map = new HashMap<String,String>();
			
		}
		
		String prev = map.get(key);
		
		// replace single quotes
		
		value = value.replaceAll("'", "\"");
		
		
		// get rid of the exec stuff that starts the AircraftType element
		if (key.equals("AircraftType") ){
		
			int k = value.indexOf("\"");
			String at = value.substring(k);
			value = at;
		}
		// remote any spaces in flight number
		if (key.equals("FlightNumber") ){
			
			String fn = value.replaceAll(" ","");
			value = fn;
		}
		
		map.put(key,  value.trim());
		return prev;
	}
	
	
	public String get(String key){
		
		return map.get(key);
	}
	
public Map<String, String> getPropertyMap(){
	
	return map;
}

@Override
public int size() {
	// TODO Auto-generated method stub
	return map.size();
}

@Override
public boolean isEmpty() {
	// TODO Auto-generated method stub
	return map.isEmpty();
}

@Override
public boolean containsKey(Object key) {
	// TODO Auto-generated method stub
	return map.containsKey(key);
}

@Override
public boolean containsValue(Object value) {
	// TODO Auto-generated method stub
	return map.containsValue(value);
}



@Override
public void putAll(Map<? extends String, ? extends String> m) {
	map.putAll(m);
	
}

@Override
public void clear() {
	map.clear();
	
}

@Override
public Set<String> keySet() {
	// TODO Auto-generated method stub
	return map.keySet();
}

@Override
public Collection<String> values() {
	// TODO Auto-generated method stub
	return map.values();
}

@Override
public Set<java.util.Map.Entry<String, String>> entrySet() {
	// TODO Auto-generated method stub
	return map.entrySet();
}

@Override
public String remove(Object key) {
	// TODO Auto-generated method stub
	return map.remove(key);
}

@Override
public String get(Object key) {
	// TODO Auto-generated method stub
	return map.get(key);
}



}
