#!/bin/bash
psql -U postgres -h localhost -d stock_ai -f ./database/schema.sql
