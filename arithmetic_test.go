package someaction

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAdd(t *testing.T) {
	type args struct {
		a int
		b int
	}
	tests := []struct {
		name string
		args args
		want int
	}{
		{"2+2=4", args{a: 2, b: 2}, 4},
		{"3+3=6", args{a: 3, b: 3}, 6},
		{"7+7=14", args{a: 7, b: 7}, 14},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Add(tt.args.a, tt.args.b); got != tt.want {
				assert.Equal(t, tt.want, got)
			}
		})
	}
}
