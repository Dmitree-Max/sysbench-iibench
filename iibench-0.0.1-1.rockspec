package = "iibench"
version = "0.0.1-1"
source = {
   url = "git+https://github.com/Dmitree-Max/sysbench-iibench"
}

description = {
   summary =
       "This is the iiBench benchmark (aka the Index Insertion Benchmark) implemented as a sysbench workload",
   detailed = [[
# sysbench-iibench

This is a [sysbench](https://github.com/akopytov/sysbench) implementation of the [iiBench Benchmark](https://github.com/tmcallaghan/iibench-mysql). The implementation is based on Mark Callaghan's [python script](https://github.com/mdcallag/mytools/blob/master/bench/ibench/iibench.py).

## Synopsis

The purpose of iiBench is to stress indexed insertion code paths in a database. You can read more about its history and design choices [here](http://www.acmebenchmarking.com/2014/11/announcing-iibench-for-mysql-in-java.html) and [here](http://smalldatum.blogspot.com/2017/06/the-insert-benchmark.html).
This implementation follows the original design and mimics the command line options closely, but provides some nice improvements and extensions on top of it, namely:
- sysbench as the only dependency
- common interface and results format with other sysbench workloads such as OLTP or [TPC-C](https://github.com/Percona-Lab/sysbench-tpcc)
- no Python-induced scalability issues
- the warmup stage
- index caching statistics reported after the warmup
- multiple tables
- multiple insert threads

# Installation

To install sysbench use [these](https://github.com/akopytov/sysbench#installing-from-binary-packages) instructions. 

You can then either use iiBench without installation directly from the source repository:
```shell
sysbench ./iibench.lua ...
```

or install it from the source repository:
```shell
luarocks make --lua-version=5.1 --local
```

or install it from [SysbenchRocks](https://rocks.sysbench.io/):
```shell
luarocks --lua-version=5.1 --server=rocks.sysbench.io --local install iibench
```

To get a summary of command line options after installation:
```shell
sysbench iibench help
```

# Usage

## Dataset

The dataset consists of the specified number of tables with the following schema:

```sql
CREATE TABLE sbtest%d(
   transactionid BIGINT NOT NULL AUTO_INCREMENT,
   dateandtime DATETIME NOT NULL,
   cashregisterid INT NOT NULL,
   customerid INT NOT NULL,
   productid INT NOT NULL,
   price FLOAT NOT NULL,
   data VARCHAR(%d) NOT NULL,
   PRIMARY KEY (transactionid)
)
```

There is also up to 3 secondary indexes in each table: on `(price, customerid)`, `(cashregisterid, price, customerid)` and `(price, dateandtime, customerid)`. All three indexes are created by default, but that can be changed with the `--num-secondary-indexes` option.

The number of rows in each table is specified with `--table-size` (10000 by default).

Tables can be optionally partitioned with a specified number of partitions and rows per partition using the following options:
- `--num-partitions` (0 by default)
- `--rows-per-partition` (0 by default, in which case is computed as `table_size / num_partitions`)

The ranges of values in numeric columns are controlled by the following options:
- `--cashregisters` (1000 by default)
- `--products` (10 000 by default)
- `--customers` (100 000 by default)
- `--max-price` (500 by default)

Strings in the `data` column are controlled by the following options:
- `--data-length-min` (10 by default)
- `--data-length-max` (10 by default) which is also used as the `VARCHAR` length
- `--data-random-pct` (50 by default) specifies the length in percent of the randomly generated suffix for each string as opposed to static prefix

## Threads and rates

The `--insert-threads` option sets the number of threads executing `INSERT`s (defaults to 1). 

The number of `SELECT` threads is calculated as `--threads` (which is the total number of threads created by sysbench) minus `--insert-threads`. 

`--select-rate` and `--insert-rate` can be used to control the number of queries per second executed by each `SELECT` and `INSERT` thread, respectively. The default for both options is 0, which means no rate limit. Alternatively, the `--insert-per-second` option can be used to specify a total limit for all `INSERT` threads.

## Limiting table size

The initial table size is specified with h`--table-size`. Since this is an `INSERT`-mostly workload, you may want to place a limit on how big the tables are allowed to grow. 

To do so, use `--with-max-table-rows=true --max-table-rows=N`, in which case the workload will start deleting oldest rows after reaching `N` rows, i.e. after inserting `max_tables_rows - table_size` rows. 

This behavior is disabled by default.

## Examples

### Prepare data and tables
```shell
sysbench iibench --mysql-socket=/tmp/mysql.sock --mysql-user=root --threads=10 --tables=10 --table-size=1000000 --num-secondary-indexes=2 --db-driver=mysql prepare
```
### Warm up 
```shell
sysbench iibench --mysql-socket=/tmp/mysql.sock --tables=10 --table-size=1000000 --stat=true warmup
```
### Run benchmark
```shell
sysbench iibench --mysql-socket=/tmp/mysql.sock --mysql-user=root --time=300 --threads=64 --report-interval=1 --tables=10 \
--table-size=1000000 --insert-threads=8 --inserts-per-second=50 --num-secondary-indexes=2 --db-driver=mysql run
```
### Cleanup
```shell
sysbench iibench --mysql-socket=/tmp/mysql.sock --mysql-user=root --threads=10 --db-driver=mysql cleanup
```
]],
   homepage = "https://github.com/Dmitree-Max/sysbench-iibench",
   license = "MIT"
}

dependencies = {
   "lua == 5.1"
}

build = {
   type = "builtin",
   modules = {
      iibench = "iibench.lua",
      index_stat = "index_stat.lua",
      iibench_common = "iibench_common.lua",
      thread_groups = "thread_groups.lua"
  }
}
