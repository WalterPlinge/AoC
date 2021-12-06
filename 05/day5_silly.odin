package day_5
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
main::proc(){
	fmt.println("Day 5")
	Point::[2]int
	Line::[2]Point
	vents:[]Line;defer delete(vents)
	{ // Load input data
		when #config(example,false){
			data:=example_data
		} else {
			data,_:=os.read_entire_file("day5.txt");defer delete(data)
		}
		point_strings:=strings.fields(string(data));defer delete(point_strings)
		vents=make([]Line,len(point_strings)/3)
		for v,i in&vents{
			p1:=strings.split(point_strings[i*3+0],",");defer delete(p1)
			p2:=strings.split(point_strings[i*3+2],",");defer delete(p2)
			v[0]=Point{strconv.atoi(p1[0]),strconv.atoi(p1[1])}
			v[1]=Point{strconv.atoi(p2[0]),strconv.atoi(p2[1])}
		}
	}
	fmt.println("\t1) Consider only horizontal and vertical lines. At how many points do at least two lines overlap?")
	{ // Part 1
		pos:map[Point]int
		for v in vents{
			p1:=v[0]
			p2:=v[1]
			lx,ly:=min(p1.x,p2.x),min(p1.y,p2.y)
			hx,hy:=max(p1.x,p2.x),max(p1.y,p2.y)
			if lx==hx do for i in ly..=hy do pos[Point{p1.x,i}]+=1
			else if ly==hy do for i in lx..=hx do pos[Point{i,p1.y}]+=1
		}
		count:=0
		for k,v in pos do if v>=2 do count+=1
		fmt.println("\t\ta)",count)
	}
	{ // Part 1 (version 2)
		pos:map[Point]int
		for v in vents{
			p1:=v[0]
			p2:=v[1]
			d:=p2-p1
			if d.x!=0&&d.y!=0 do continue
			for n in&d do if n!=0 do n/=abs(n)
			for p:=p1;p!=p2;p+=d do pos[p]+=1
			pos[p2]+=1
		}
		count:=0
		for k,v in pos do if v>=2 do count+=1
		fmt.println("\t\tb)",count)
	}
	fmt.println("\t2) Consider all of the lines. At how many points do at least two lines overlap?")
	{ // Part 2
		pos:map[Point]int
		for v in vents{
			p1:=v[0]
			p2:=v[1]
			lx,ly:=min(p1.x,p2.x),min(p1.y,p2.y)
			hx,hy:=max(p1.x,p2.x),max(p1.y,p2.y)
			if lx==hx do for i in ly..=hy do pos[Point{p1.x,i}]+=1
			else if ly==hy do for i in lx..=hx do pos[Point{i,p1.y}]+=1
			else if p1.x<p2.x&&p1.y<p2.y do for x,y:=p1.x,p1.y;x<=p2.x&&y<=p2.y;{
					pos[Point{x,y}]+=1
					x+=1
					y+=1
			}else if p1.x<p2.x&&p2.y<p1.y do for x,y:=p1.x,p1.y;x<=p2.x&&y>=p2.y;{
					pos[Point{x,y}]+=1
					x+=1
					y-=1
			}else if p2.x<p1.x&&p1.y<p2.y do for x,y:=p1.x,p1.y;x>=p2.x&&y<=p2.y;{
					pos[Point{x,y}]+=1
					x-=1
					y+=1
			}else if p2.x<p1.x&&p2.y<p1.y do for x,y:=p1.x,p1.y;x>=p2.x&&y>=p2.y;{
					pos[Point{x,y}]+=1
					x-=1
					y-=1
			}
		}
		count:=0
		for k,v in pos do if v>=2 do count+=1
		fmt.println("\t\ta)",count)
	}
	{ // Part 2 (version 2)
		pos:map[Point]int
		for v in vents{
			p1:=v[0]
			p2:=v[1]
			d:=p2-p1
			for n in&d do if n!=0 do n/=abs(n)
			for p:=p1;p!=p2;p+=d do pos[p]+=1
			pos[p2]+=1
		}
		count:=0
		for k,v in pos do if v>=2 do count+=1
		fmt.println("\t\tb)",count)
	}
}

example_data := \
`0,9 -> 5,9
8,0 -> 0,8
9,4 -> 3,4
2,2 -> 2,1
7,0 -> 7,4
6,4 -> 2,0
0,9 -> 2,9
3,4 -> 1,4
0,0 -> 8,8
5,5 -> 8,2`
