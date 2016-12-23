package com.easyjet.fcp.test.io;

import java.util.List;

import com.easyjet.fcp.test.domain.Fare;

public interface IFareWriter {

	void write(List<Fare> f);
}
