Introduction
============

Briefly described, liblognorm is a tool to normalize log data.

People who need to take a look at logs often have a common problem. Logs 
from different machines (from different vendors) usually have different 
formats. Even if it is the same type of log (e.g. from firewalls), the log 
entries are so different, that it is pretty hard to read these. This is 
where liblognorm comes into the game. With this tool you can normalize all 
your logs. All you need is liblognorm and its dependencies and a sample 
database that fits the logs you want to normalize.

So, for example, if you have traffic logs from three different firewalls, 
liblognorm will be able to "normalize" the events into generic ones. Among 
others, it will extract source and destination ip addresses and ports and 
make them available via well-defined fields. As the end result, a common log 
analysis application will be able to work on that common set and so this 
backend will be independent from the actual firewalls feeding it. Even 
better, once we have a well-understood interim format, it is also easy to 
convert that into any other vendor specific format, so that you can use that 
vendor's analysis tool.

By design, liblognorm is constructed as a library. Thus, it can be used by 
other tools.

In short, liblognorm works by:

	1. Matching a line to a rule from predefined configuration;
	2. Picking out variable fields from the line;
	3. Returning them as a JSON hash object.

Then, a consumer of this object can construct new, normalized log line
on its own.
