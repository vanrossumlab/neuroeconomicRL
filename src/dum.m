flip_period=2

y=ones(1,20)
for t= 2:20
    if flip_period >0 && mod(t, flip_period) >= flip_period/2
         y(t)=-1
    end
end
plot(y)
