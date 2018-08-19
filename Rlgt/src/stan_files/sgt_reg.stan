// Seasonal Global Trend (SGT) algorithm

data {  
	int<lower=2> SEASONALITY;
	real<lower=0> CAUCHY_SD;
	real MIN_POW_TREND;  real MAX_POW_TREND;
	real<lower=0> MIN_SIGMA;
	real<lower=1> MIN_NU; real<lower=1> MAX_NU;
	int<lower=1> N;
	int<lower=1> J;
	vector<lower=0>[N] y;
	matrix[N, J] xreg;
	real<lower=0> POW_TREND_ALPHA; real<lower=0> POW_TREND_BETA; 
}
parameters {
  vector[J]  regCoef;
	real<lower=MIN_NU,upper=MAX_NU> nu; 
	real<lower=0> sigma;
	real <lower=0,upper=1>levSm;
	real <lower=0,upper=1>sSm;
	real <lower=0,upper=1>powx;
	real <lower=0,upper=1> powTrendBeta;
	real coefTrend;
	real <lower=MIN_SIGMA> offsetSigma;
	vector[SEASONALITY] initSu; //unnormalized
} 
transformed parameters {
	real <lower=MIN_POW_TREND,upper=MAX_POW_TREND>powTrend;
	vector<lower=0>[N] l;
	vector<lower=0>[N+SEASONALITY] s;
	vector[N] r; //regression component
	real sumsu;
	
	sumsu = 0;
	for (i in 1:SEASONALITY) 
		sumsu = sumsu+ initSu[i];
	for (i in 1:SEASONALITY) 
		s[i] = initSu[i]*SEASONALITY/sumsu;
	s[SEASONALITY+1] = s[1];
	l[1] = y[1]/s[1];
	r[1] = xreg[1,:] * regCoef;
	powTrend= (MAX_POW_TREND-MIN_POW_TREND)*powTrendBeta+MIN_POW_TREND;
	
	for (t in 2:N) {
	  r[t] = xreg[t,:] * regCoef;
		l[t] = levSm*(y[t]-r[t])/(s[t]) + (1-levSm)*l[t-1] ;  //E(y[t])=l[t]*s[t]
		s[t+SEASONALITY] = sSm*(y[t]-r[t])/l[t]+(1-sSm)*s[t];
	}
}
model {
	real expVal;

	sigma ~ cauchy(0,CAUCHY_SD) T[0,];
	offsetSigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];	
	coefTrend ~ cauchy(0, CAUCHY_SD);
	powTrendBeta ~ beta(POW_TREND_ALPHA, POW_TREND_BETA);
  regCoef ~ normal(0,1);

	for (t in 1:SEASONALITY)
		initSu[t] ~ cauchy (1, 0.3) T[0.01,];
	
	for (t in 2:N) {
	  expVal = (l[t-1]+ coefTrend*l[t-1]^powTrend)*s[t] + r[t];
	  y[t] ~ student_t(nu, expVal, sigma*expVal^powx+ offsetSigma);
	}
}