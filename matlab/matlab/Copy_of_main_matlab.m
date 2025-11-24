function [position, velocity, acc] = main_matlab(Xh, Vh)
    T = 20;

    %dT2 = calculate_dt_evaluation_real(ceil(remainingGreenTime), ceil(remainingRedTime));
    dT2 = calculate_dt_evaluation_real(15, 30);
    [x_pred2] = Opt_method_second(Xh, Vh, 400, 0, dT2);
    [xinit_type2, vinit_type2, ainit_type2] = calculate_interpolation_real(dT2, x_pred2);
    velocity = vinit_type2;
    position = xinit_type2;
    acc = ainit_type2;
end



