package main

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	calc "github.com/datosh-org/most-secure-calculator"
)

func main() {
	e := echo.New()

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.GET("/add/:a/:b", add)

	e.Logger.Fatal(e.Start(":8080"))
}

func add(c echo.Context) error {
	aParam := c.Param("a")
	bParam := c.Param("b")

	a, err := strconv.Atoi(aParam)
	if err != nil {
		return err
	}
	b, err := strconv.Atoi(bParam)
	if err != nil {
		return err
	}

	return c.JSON(http.StatusOK, struct {
		A      int
		B      int
		Result int
	}{
		A:      a,
		B:      b,
		Result: calc.Add(a, b),
	})
}
